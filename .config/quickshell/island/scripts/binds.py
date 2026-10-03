#!/usr/bin/env python3
"""Reads / edits the `bind*` lines of hyprland.conf.
  binds.py list
  binds.py set <line> <flag> <mods> <key> <dispatcher> <arg>
  binds.py add <flag> <mods> <key> <dispatcher> <arg>
  binds.py del <line>
Prints JSON. Writes keep a copy of the previous file in hyprland.conf.pre-edit and reload Hyprland."""
import json
import os
import re
import shutil
import subprocess
import sys

CONF = os.environ.get("HYPR_CONF") or os.path.expanduser("~/.config/hypr/hyprland.conf")
BIND = re.compile(r"^\s*(bind[a-z]*)\s*=\s*(.*)$")


def variables(lines):
    v = {}
    for ln in lines:
        m = re.match(r"^\s*\$(\w+)\s*=\s*(\S+)", ln)
        if m:
            v[m.group(1)] = m.group(2)
    return v


def parse(ln):
    m = BIND.match(ln.rstrip("\n"))
    if not m:
        return None
    flag, rest = m.groups()
    comment = ""
    c = re.search(r"\s{2,}#.*$", rest)
    if c:
        comment, rest = c.group(0).strip(), rest[:c.start()]
    parts = [p.strip() for p in rest.split(",", 3)]
    while len(parts) < 4:
        parts.append("")
    mods, key, disp, arg = parts
    if arg.startswith("#"):          # `bind = X, P, pseudo, # dwindle` -> the trailing text is a comment
        comment, arg = arg, ""
    return {"flag": flag, "mods": mods, "key": key, "disp": disp, "arg": arg, "comment": comment}


def build(flag, mods, key, disp, arg, comment=""):
    s = f"{flag} = {mods}, {key}, {disp}"
    if arg:
        s += f", {arg}"
    if comment:
        s += f"  {comment}"
    return s + "\n"


def norm(mods, key, vars_):
    ms = mods
    for k, v in vars_.items():
        ms = ms.replace("$" + k, v)
    return (" ".join(sorted(ms.upper().replace("_", " ").split())), key.strip().upper())


def read():
    with open(CONF) as f:
        return f.readlines()


def write(lines):
    shutil.copyfile(CONF, CONF + ".pre-edit")
    tmp = CONF + ".tmp"
    with open(tmp, "w") as f:
        f.writelines(lines)
    os.replace(tmp, CONF)
    subprocess.run(["hyprctl", "reload"], capture_output=True)


def conflict(lines, mods, key, skip=None):
    v = variables(lines)
    want = norm(mods, key, v)
    for i, ln in enumerate(lines):
        if i == skip:
            continue
        b = parse(ln)
        if b and b["flag"] != "bindm" and norm(b["mods"], b["key"], v) == want:
            return f"{mods or 'no mod'}+{key} is already used by line {i + 1} ({b['disp']} {b['arg']})".strip()
    return None


def main():
    cmd = sys.argv[1]
    lines = read()
    if cmd == "list":
        v = variables(lines)
        out = []
        for i, ln in enumerate(lines):
            b = parse(ln)
            if b:
                desc = ""
                if i > 0 and lines[i - 1].lstrip().startswith("#"):
                    desc = lines[i - 1].strip().lstrip("# ").strip()
                shown = b["mods"]
                for k, val in v.items():
                    shown = shown.replace("$" + k, val)
                out.append(dict(b, line=i, shown=shown, desc=desc))
        print(json.dumps(out))
        return
    try:
        if cmd == "set":
            i = int(sys.argv[2])
            flag, mods, key, disp, arg = sys.argv[3:8]
            old = parse(lines[i])
            err = conflict(lines, mods, key, skip=i)
            if err and flag != "bindm":
                print(json.dumps({"ok": False, "error": err})); return
            lines[i] = build(flag, mods, key, disp, arg, old["comment"] if old else "")
        elif cmd == "add":
            flag, mods, key, disp, arg = sys.argv[2:7]
            err = conflict(lines, mods, key)
            if err:
                print(json.dumps({"ok": False, "error": err})); return
            if lines and not lines[-1].endswith("\n"):
                lines[-1] += "\n"
            lines.append(build(flag, mods, key, disp, arg))
        elif cmd == "del":
            del lines[int(sys.argv[2])]
        else:
            raise ValueError("unknown command")
        write(lines)
        print(json.dumps({"ok": True}))
    except Exception as e:  # noqa: BLE001
        print(json.dumps({"ok": False, "error": str(e)}))


main()
