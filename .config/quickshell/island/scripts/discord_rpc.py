#!/usr/bin/env python3
"""Waybar module: Discord voice status + controls, through Discord's local RPC (IPC) socket.

  discord_rpc.py            -> daemon, prints one JSON line per update (waybar custom module)
  discord_rpc.py mute       -> toggle mute   (talks to the running daemon)
  discord_rpc.py deafen     -> toggle deafen
  discord_rpc.py leave      -> leave the voice channel

Needs ~/.config/waybar/scripts/discord_rpc.json : {"client_id": "...", "client_secret": "..."}
(see the setup steps given when the module shows "setup").
"""
import html
import json
import os
import select
import socket
import struct
import sys
import time
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

CONF = Path.home() / ".config/quickshell/island/scripts/discord_rpc.json"
TOKEN = Path.home() / ".cache/waybar-discord-token.json"
RUNTIME = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
CTL = f"{RUNTIME}/waybar-discord.sock"
PIDFILE = f"{RUNTIME}/waybar-discord.pid"
STATE_FILE = f"{RUNTIME}/waybar-discord-state.json"
SCOPES = ["rpc", "rpc.voice.read", "rpc.voice.write"]
REDIRECT = "http://localhost"

I_DISCORD = "\U000F066F"
I_MIC = "\U000F036C"
I_MIC_OFF = "\U000F036D"
I_HEAD = "\U000F02CB"
I_HEAD_OFF = "\U000F07CE"

SETUP_TIP = (
    "<b>Discord : configuration</b>\n"
    "1. discord.com/developers/applications → New Application\n"
    "2. OAuth2 → Redirects → ajouter http://localhost\n"
    "3. App Testers → ajouter ton compte Discord\n"
    "4. Mettre client_id / client_secret dans\n"
    "   ~/.config/waybar/scripts/discord_rpc.json"
)


def emit(text="", cls="offline", tip=""):
    print(json.dumps({"text": text, "class": cls, "tooltip": tip}), flush=True)


def fmt_duration(sec):
    sec = int(sec)
    h, rest = divmod(sec, 3600)
    m, s = divmod(rest, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


# ---------------------------------------------------------------- IPC

class IPC:
    def __init__(self):
        self.sock = None
        self.pending = []

    def connect(self, client_id):
        for d in (RUNTIME, f"{RUNTIME}/app/com.discordapp.Discord", f"{RUNTIME}/snap.discord"):
            for i in range(10):
                s = socket.socket(socket.AF_UNIX)
                try:
                    s.connect(f"{d}/discord-ipc-{i}")
                except OSError:
                    s.close()
                    continue
                self.sock = s
                s.settimeout(10)
                self.send(0, {"v": 1, "client_id": client_id})
                self.recv()  # READY
                return
        raise ConnectionError("discord ipc not found")

    def send(self, op, data):
        raw = json.dumps(data).encode()
        self.sock.sendall(struct.pack("<II", op, len(raw)) + raw)

    def _exact(self, n):
        buf = b""
        while len(buf) < n:
            chunk = self.sock.recv(n - len(buf))
            if not chunk:
                raise ConnectionError("discord closed the socket")
            buf += chunk
        return buf

    def recv(self):
        op, n = struct.unpack("<II", self._exact(8))
        msg = json.loads(self._exact(n))
        if op == 2:
            raise ConnectionError("discord closed the connection")
        if op == 3:
            self.send(4, msg)
        return op, msg

    def cmd(self, cmd, args=None, evt=None, wait=True, timeout=10):
        nonce = uuid.uuid4().hex
        payload = {"cmd": cmd, "args": args or {}, "nonce": nonce}
        if evt:
            payload["evt"] = evt
        self.send(1, payload)
        if not wait:
            return None
        self.sock.settimeout(timeout)
        try:
            while True:
                _, msg = self.recv()
                if msg.get("nonce") == nonce:
                    return msg
                self.pending.append(msg)
        finally:
            self.sock.settimeout(10)


# ---------------------------------------------------------------- auth

def oauth(conf, **data):
    data.update(client_id=conf["client_id"], client_secret=conf["client_secret"])
    req = urllib.request.Request(
        "https://discord.com/api/v10/oauth2/token",
        urllib.parse.urlencode(data).encode(),
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "DiscordBot (waybar-discord, 1.0)",
        },
    )
    with urllib.request.urlopen(req, timeout=15) as r:
        tok = json.load(r)
    tok["expires_at"] = time.time() + tok.get("expires_in", 0)
    TOKEN.parent.mkdir(parents=True, exist_ok=True)
    TOKEN.write_text(json.dumps(tok))
    TOKEN.chmod(0o600)
    return tok


def load_token():
    try:
        return json.loads(TOKEN.read_text())
    except (OSError, ValueError):
        return None


def authenticate(ipc, conf):
    """Returns my user id."""
    tok = load_token()
    if tok and tok.get("expires_at", 0) < time.time() + 60 and tok.get("refresh_token"):
        try:
            tok = oauth(conf, grant_type="refresh_token", refresh_token=tok["refresh_token"])
        except Exception:
            tok = None
    if tok:
        r = ipc.cmd("AUTHENTICATE", {"access_token": tok["access_token"]})
        if r.get("evt") != "ERROR":
            return r["data"]["user"]["id"]

    emit(f"{I_DISCORD} autorise…", "setup", "Accepte la demande d'autorisation dans la fenêtre Discord")
    r = ipc.cmd("AUTHORIZE", {"client_id": conf["client_id"], "scopes": SCOPES}, timeout=300)
    if r.get("evt") == "ERROR":
        raise PermissionError(r["data"].get("message", "authorize refused"))
    tok = oauth(conf, grant_type="authorization_code", code=r["data"]["code"], redirect_uri=REDIRECT)
    r = ipc.cmd("AUTHENTICATE", {"access_token": tok["access_token"]})
    if r.get("evt") == "ERROR":
        raise PermissionError(r["data"].get("message", "authenticate refused"))
    return r["data"]["user"]["id"]


# ---------------------------------------------------------------- state

class State:
    def __init__(self):
        self.settings = {}
        self.channel = None  # {"id", "name", "members": {uid: {...}}}
        self.joined = 0.0
        self.speaking = set()


def parse_member(v):
    u = v["user"]
    vs = v.get("voice_state", {})
    return {
        "name": v.get("nick") or u.get("global_name") or u["username"],
        "mute": bool(vs.get("self_mute") or vs.get("mute")),
        "deaf": bool(vs.get("self_deaf") or vs.get("deaf")),
    }


VOICE_EVENTS = ("VOICE_STATE_CREATE", "VOICE_STATE_UPDATE", "VOICE_STATE_DELETE", "SPEAKING_START", "SPEAKING_STOP")


def refresh_channel(ipc, st):
    old = st.channel["id"] if st.channel else None
    d = ipc.cmd("GET_SELECTED_VOICE_CHANNEL").get("data")
    if old and (not d or d["id"] != old):
        for evt in VOICE_EVENTS:
            ipc.cmd("UNSUBSCRIBE", {"channel_id": old}, evt, wait=False)
    if not d:
        st.channel = None
        st.speaking.clear()
        return
    members = {v["user"]["id"]: parse_member(v) for v in d.get("voice_states", [])}
    name = d.get("name") or ", ".join(m["name"] for m in members.values()) or "Appel"
    if d["id"] != old:
        st.joined = time.time()
        st.speaking.clear()
        for evt in VOICE_EVENTS:
            ipc.cmd("SUBSCRIBE", {"channel_id": d["id"]}, evt, wait=False)
    st.channel = {"id": d["id"], "name": name, "members": members}


def handle(ipc, st, msg):
    if msg.get("cmd") != "DISPATCH":
        return
    evt, data = msg.get("evt"), msg.get("data") or {}
    if evt == "VOICE_SETTINGS_UPDATE":
        st.settings = data
    elif evt == "VOICE_CHANNEL_SELECT":
        refresh_channel(ipc, st)
    elif not st.channel:
        return
    elif evt in ("VOICE_STATE_CREATE", "VOICE_STATE_UPDATE"):
        st.channel["members"][data["user"]["id"]] = parse_member(data)
    elif evt == "VOICE_STATE_DELETE":
        st.channel["members"].pop(data["user"]["id"], None)
        st.speaking.discard(data["user"]["id"])
    elif evt == "SPEAKING_START":
        st.speaking.add(data["user_id"])
    elif evt == "SPEAKING_STOP":
        st.speaking.discard(data["user_id"])


def dump_state(st, connected=True):
    ch = st.channel
    data = {
        "connected": connected,
        "mute": bool(st.settings.get("mute")),
        "deaf": bool(st.settings.get("deaf")),
        "in_vol": (st.settings.get("input") or {}).get("volume", 100),
        "out_vol": (st.settings.get("output") or {}).get("volume", 100),
        "channel": None if not ch else {
            "name": ch["name"],
            "joined": st.joined,
            "members": [
                dict(m, id=uid, speaking=uid in st.speaking) for uid, m in ch["members"].items()
            ],
        },
    }
    tmp = STATE_FILE + ".tmp"
    Path(tmp).write_text(json.dumps(data))
    os.replace(tmp, STATE_FILE)


def render(st):
    dump_state(st)
    deaf = bool(st.settings.get("deaf"))
    mute = bool(st.settings.get("mute")) or deaf
    if not st.channel:
        return emit(I_DISCORD, "idle", "Discord — pas en vocal\n<i>clic : ouvrir le panneau</i>")

    ch = st.channel
    name = ch["name"] if len(ch["name"]) <= 20 else ch["name"][:19] + "…"
    mic = I_MIC_OFF if mute else I_MIC
    head = f" {I_HEAD_OFF}" if deaf else ""
    speaking = bool(st.speaking)
    text = f"{I_DISCORD}  {html.escape(name)}  {mic}{head}  <span foreground='#8a8494'>{len(ch['members'])} · {fmt_duration(time.time() - st.joined)}</span>"

    lines = [f"<b>{html.escape(ch['name'])}</b>  ({fmt_duration(time.time() - st.joined)})", ""]
    for uid, m in ch["members"].items():
        flags = (f" {I_HEAD_OFF}" if m["deaf"] else "") + (f" {I_MIC_OFF}" if m["mute"] else "")
        label = html.escape(m["name"])
        if uid in st.speaking:
            label = f"<span foreground='#a6e3a1'><b>{label}</b></span>"
        lines.append(f"●  {label}{flags}")
    lines += ["", "<i>clic : panneau · clic droit : mute · clic milieu : quitter</i>"]

    cls = "deafened" if deaf else "muted" if mute else "voice"
    if speaking and cls == "voice":
        cls = "voice speaking"
    emit(text, cls, "\n".join(lines))


# ---------------------------------------------------------------- daemon

def run_command(ipc, st, word):
    if word == "mute":
        ipc.cmd("SET_VOICE_SETTINGS", {"mute": not st.settings.get("mute")}, wait=False)
    elif word == "deafen":
        ipc.cmd("SET_VOICE_SETTINGS", {"deaf": not st.settings.get("deaf")}, wait=False)
    elif word.startswith("in_vol "):
        ipc.cmd("SET_VOICE_SETTINGS", {"input": {"volume": float(word[7:])}}, wait=False)
    elif word.startswith("out_vol "):
        ipc.cmd("SET_VOICE_SETTINGS", {"output": {"volume": float(word[8:])}}, wait=False)
    elif word == "leave" and st.channel:
        ipc.cmd("SELECT_VOICE_CHANNEL", {"channel_id": None, "force": True}, wait=False)


def session(conf, ctl):
    ipc = IPC()
    ipc.connect(conf["client_id"])
    authenticate(ipc, conf)
    st = State()
    for evt in ("VOICE_SETTINGS_UPDATE", "VOICE_CHANNEL_SELECT"):
        ipc.cmd("SUBSCRIBE", evt=evt)
    st.settings = ipc.cmd("GET_VOICE_SETTINGS").get("data") or {}
    refresh_channel(ipc, st)

    try:
        ctl.setblocking(False)
        try:
            while True:
                ctl.recv(64)  # drop stale commands from while we were away
        except BlockingIOError:
            pass
        while True:
            while ipc.pending:
                handle(ipc, st, ipc.pending.pop(0))
            render(st)
            ready, _, _ = select.select([ipc.sock, ctl], [], [], 1.0)
            if ctl in ready:
                run_command(ipc, st, ctl.recv(64).decode().strip())
            if ipc.sock in ready:
                _, msg = ipc.recv()
                handle(ipc, st, msg)
    finally:
        ipc.sock.close()


def replace_old_instance():
    try:
        old = int(Path(PIDFILE).read_text())
        if old != os.getpid() and "discord_rpc.py" in Path(f"/proc/{old}/cmdline").read_text():
            os.kill(old, 15)
    except (OSError, ValueError):
        pass
    Path(PIDFILE).write_text(str(os.getpid()))


def daemon():
    replace_old_instance()
    try:
        os.unlink(CTL)
    except FileNotFoundError:
        pass
    ctl = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    ctl.bind(CTL)

    while True:
        try:
            conf = json.loads(CONF.read_text())
            conf["client_id"], conf["client_secret"]
        except (OSError, ValueError, KeyError):
            emit(f"{I_DISCORD} setup", "setup", SETUP_TIP)
            time.sleep(5)
            continue
        try:
            session(conf, ctl)
        except PermissionError as e:
            emit(f"{I_DISCORD} refusé", "setup", html.escape(f"Autorisation Discord refusée : {e}\n\n") + SETUP_TIP)
            time.sleep(10)
        except (ConnectionError, OSError, ValueError, KeyError, struct.error):
            dump_state(State(), connected=False)
            emit("", "offline", "")
            time.sleep(3)


def main():
    if len(sys.argv) > 1:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        try:
            s.sendto(sys.argv[1].encode(), CTL)
        except OSError:
            sys.exit("daemon not running")
        return
    daemon()


if __name__ == "__main__":
    main()
