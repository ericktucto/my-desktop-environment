#!/usr/bin/env python3
"""Grabador de pantalla de la shell (RecorderStore): arranca, detiene y revisa wf-recorder.

wf-recorder corre aparte de la shell (sesión propia), así que una recarga de qs no corta la grabación.
El estado queda en $XDG_RUNTIME_DIR/stixshell/recorder.json.

  start --file F (--output NOMBRE | --geometry "x,y WxH") [--internal] [--mic]
        [--encoder E] [--device D] [--fps N] [--dnd-before]
  stop      detiene (SIGINT, deja el .mp4 cerrado), descarga el audio temporal e imprime el archivo
  status    imprime el estado en JSON: {} si no hay nada, {"alive": true, ...} si graba,
            {"dead": true, ...} si wf-recorder murió solo (y limpia)
"""
import argparse
import json
import os
import signal
import subprocess
import sys
import time

RUN = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "stixshell")
STATE = os.path.join(RUN, "recorder.json")
LOG = os.path.join(RUN, "recorder.log")
MIX = "stixshell_rec"  # salida temporal donde se mezclan el audio interno y el micrófono


def pactl(*args):
    r = subprocess.run(["pactl", *args], capture_output=True, text=True)
    return r.returncode, r.stdout.strip()


def load_state():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def alive(pid):
    try:
        with open(f"/proc/{pid}/comm") as f:
            return f.read().strip() == "wf-recorder"
    except OSError:
        return False


def unload(modules):
    for m in modules:
        pactl("unload-module", str(m))


def clear_state():
    try:
        os.remove(STATE)
    except OSError:
        pass


def last_log_line():
    try:
        with open(LOG, errors="replace") as f:
            lines = [l.strip() for l in f.read().splitlines() if l.strip()]
        return lines[-1] if lines else ""
    except OSError:
        return ""


def audio_device(internal, mic, modules):
    """Dispositivo de audio de wf-recorder y, si hace falta, la mezcla (se anotan sus módulos)."""
    if not internal and not mic:
        return None
    _, sink = pactl("get-default-sink")
    _, source = pactl("get-default-source")
    if internal and not mic:
        return sink + ".monitor"
    if mic and not internal:
        return source
    code, out = pactl("load-module", "module-null-sink", f"sink_name={MIX}",
                      f"sink_properties=device.description={MIX}")
    if code != 0:
        raise RuntimeError("no se pudo crear la mezcla de audio")
    modules.append(out)
    for src in (sink + ".monitor", source):
        code, out = pactl("load-module", "module-loopback", f"source={src}", f"sink={MIX}", "latency_msec=40")
        if code != 0:
            raise RuntimeError("no se pudo conectar el audio a la mezcla")
        modules.append(out)
    return MIX + ".monitor"


def cmd_start(a):
    os.makedirs(RUN, exist_ok=True)
    os.makedirs(os.path.dirname(a.file), exist_ok=True)
    cur = load_state()
    if cur and alive(cur.get("pid", 0)):
        print("ya hay una grabación en curso", file=sys.stderr)
        return 1
    clear_state()

    modules = []
    try:
        dev = audio_device(a.internal, a.mic, modules)
    except RuntimeError as e:
        unload(modules)
        print(str(e), file=sys.stderr)
        return 1

    argv = ["wf-recorder", "-y", "-r", str(a.fps), "-c", a.encoder]
    if a.encoder.endswith("vaapi"):
        argv += ["-d", a.device]
    argv += ["-g", a.geometry] if a.geometry else ["-o", a.output]
    if dev:
        argv.append("--audio=" + dev)
    argv += ["-f", a.file]

    try:
        with open(LOG, "wb") as log:
            proc = subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=log, stderr=log, start_new_session=True)
    except FileNotFoundError:
        unload(modules)
        print("wf-recorder no está instalado (sudo xbps-install wf-recorder)", file=sys.stderr)
        return 1
    time.sleep(1.2)
    if proc.poll() is not None:
        unload(modules)
        print(last_log_line() or "wf-recorder terminó al arrancar", file=sys.stderr)
        return 1

    state = {"pid": proc.pid, "file": a.file, "start": int(time.time() * 1000), "modules": modules,
             "internal": a.internal, "mic": a.mic, "dndBefore": a.dnd_before}
    with open(STATE, "w") as f:
        json.dump(state, f)
    return 0


def cmd_stop(_):
    st = load_state()
    if not st:
        return 0
    pid = st.get("pid", 0)
    if alive(pid):
        os.kill(pid, signal.SIGINT)
        for _ in range(80):  # hasta 8 s para que cierre el archivo
            if not alive(pid):
                break
            time.sleep(0.1)
        else:
            os.kill(pid, signal.SIGKILL)
    unload(st.get("modules", []))
    clear_state()
    f = st.get("file", "")
    if f and os.path.exists(f) and os.path.getsize(f) > 0:
        print(f)
    return 0


def cmd_status(_):
    st = load_state()
    if not st:
        print("{}")
        return 0
    if alive(st.get("pid", 0)):
        st["alive"] = True
    else:
        unload(st.get("modules", []))
        clear_state()
        st = {"dead": True, "dndBefore": st.get("dndBefore", False), "file": st.get("file", "")}
    print(json.dumps(st))
    return 0


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("start")
    s.add_argument("--file", required=True)
    g = s.add_mutually_exclusive_group(required=True)
    g.add_argument("--output")
    g.add_argument("--geometry")
    s.add_argument("--internal", action="store_true")
    s.add_argument("--mic", action="store_true")
    s.add_argument("--encoder", default="h264_vaapi")
    s.add_argument("--device", default="/dev/dri/renderD128")
    s.add_argument("--fps", type=int, default=60)
    s.add_argument("--dnd-before", action="store_true")
    sub.add_parser("stop")
    sub.add_parser("status")
    a = p.parse_args()
    return {"start": cmd_start, "stop": cmd_stop, "status": cmd_status}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
