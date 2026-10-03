#!/usr/bin/env python3
"""Prints one JSON line of system stats every ~1.5 s (CPU, RAM, GPU, disk, network, top processes)."""
import glob
import json
import os
import subprocess
import time

INTERVAL = 1.5


def cpu_times():
    out = {}
    with open("/proc/stat") as f:
        for ln in f:
            if ln.startswith("cpu"):
                p = ln.split()
                v = list(map(int, p[1:9]))
                out[p[0]] = (sum(v) - v[3] - v[4], sum(v))  # busy, total (minus idle + iowait)
    return out


def meminfo():
    m = {}
    with open("/proc/meminfo") as f:
        for ln in f:
            k, v = ln.split(":")
            m[k] = int(v.split()[0]) * 1024
    return m


def net_bytes():
    rx = tx = 0
    with open("/proc/net/dev") as f:
        for ln in list(f)[2:]:
            name, data = ln.split(":")
            if name.strip() == "lo":
                continue
            p = data.split()
            rx += int(p[0])
            tx += int(p[8])
    return rx, tx


def cpu_temp():
    for h in glob.glob("/sys/class/hwmon/hwmon*"):
        try:
            if open(h + "/name").read().strip() in ("coretemp", "k10temp", "zenpower"):
                return int(open(h + "/temp1_input").read()) / 1000
        except OSError:
            pass
    return None


def gpu():
    try:
        r = subprocess.run(
            ["nvidia-smi", "--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,fan.speed",
             "--format=csv,noheader,nounits"], capture_output=True, text=True, timeout=2)
        p = [x.strip() for x in r.stdout.strip().split(",")]
        f = lambda x: float(x) if x not in ("[N/A]", "") else None
        return {"name": p[0], "util": f(p[1]), "mem_used": f(p[2]), "mem_total": f(p[3]),
                "temp": f(p[4]), "power": f(p[5]), "fan": f(p[6])}
    except Exception:
        return None


def top():
    try:
        r = subprocess.run(["ps", "-eo", "comm,pcpu,rss", "--sort=-pcpu", "--no-headers"], capture_output=True, text=True, timeout=2)
        agg = {}
        for ln in r.stdout.splitlines():
            p = ln.rsplit(None, 2)
            if len(p) != 3:
                continue
            a = agg.setdefault(p[0], [0.0, 0])
            a[0] += float(p[1])
            a[1] += int(p[2]) * 1024
        rows = sorted(agg.items(), key=lambda kv: -kv[1][0])[:5]
        return [{"name": n, "cpu": round(v[0], 1), "mem": v[1]} for n, v in rows]
    except Exception:
        return []


def disk(path):
    s = os.statvfs(path)
    total = s.f_blocks * s.f_frsize
    return {"path": path, "used": total - s.f_bavail * s.f_frsize, "total": total}


prev_cpu, prev_net, prev_t = cpu_times(), net_bytes(), time.time()
while True:
    time.sleep(INTERVAL)
    now_cpu, now_net, now_t = cpu_times(), net_bytes(), time.time()
    dt = max(now_t - prev_t, 0.001)
    pct = {}
    for k, (b, t) in now_cpu.items():
        pb, pt = prev_cpu.get(k, (b, t))
        pct[k] = 100.0 * (b - pb) / max(t - pt, 1)
    cores = [round(pct[k], 1) for k in sorted((k for k in pct if k != "cpu"), key=lambda s: int(s[3:]))]
    m = meminfo()
    mhz = []
    try:
        mhz = [float(l.split(":")[1]) for l in open("/proc/cpuinfo") if l.startswith("cpu MHz")]
    except OSError:
        pass
    disks = [disk("/")]
    if os.path.ismount("/home"):
        disks.append(disk("/home"))
    out = {
        "cpu": round(pct.get("cpu", 0), 1),
        "cores": cores,
        "cpu_temp": cpu_temp(),
        "cpu_mhz": round(sum(mhz) / len(mhz)) if mhz else None,
        "load": os.getloadavg(),
        "mem_total": m["MemTotal"],
        "mem_used": m["MemTotal"] - m["MemAvailable"],
        "swap_total": m.get("SwapTotal", 0),
        "swap_used": m.get("SwapTotal", 0) - m.get("SwapFree", 0),
        "gpu": gpu(),
        "disks": disks,
        "net_down": (now_net[0] - prev_net[0]) / dt,
        "net_up": (now_net[1] - prev_net[1]) / dt,
        "uptime": float(open("/proc/uptime").read().split()[0]),
        "top": top(),
    }
    print(json.dumps(out), flush=True)
    prev_cpu, prev_net, prev_t = now_cpu, now_net, now_t
