#!/usr/bin/env python3
"""Agente de emparejamiento de Bluetooth para la shell (BluetoothStore).

BlueZ le pregunta al agente cuando un dispositivo pide confirmar un código, un PIN o una autorización.
La shell habla con él por líneas JSON:

  stdout (agente → shell)
    {"type": "ready"} | {"type": "error", "message": "…"}
    {"id": 3, "type": "confirm"|"pin"|"passkey"|"authorize", "device": "/org/bluez/hci0/dev_…", "name": "…", "passkey": 123456}
    {"type": "display", "device": "…", "name": "…", "passkey": 123456} (o "pin": "0000"): mostrar, sin respuesta
    {"type": "cancel"}                                             BlueZ canceló lo pendiente
  stdin (shell → agente)
    {"id": 3, "accept": true, "value": "1234"}                      value: el PIN o el passkey que se escribió

Si stdin se cierra (la shell murió), el agente se desregistra y termina.
"""
import json
import sys

import warnings

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

warnings.filterwarnings("ignore", category=DeprecationWarning)

AGENT_PATH = "/org/stixshell/agent"
CAPABILITY = "KeyboardDisplay"

XML = """
<node>
  <interface name="org.bluez.Agent1">
    <method name="Release"/>
    <method name="RequestPinCode"><arg type="o" direction="in"/><arg type="s" direction="out"/></method>
    <method name="DisplayPinCode"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
    <method name="RequestPasskey"><arg type="o" direction="in"/><arg type="u" direction="out"/></method>
    <method name="DisplayPasskey"><arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/></method>
    <method name="RequestConfirmation"><arg type="o" direction="in"/><arg type="u" direction="in"/></method>
    <method name="RequestAuthorization"><arg type="o" direction="in"/></method>
    <method name="AuthorizeService"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
    <method name="Cancel"/>
  </interface>
</node>
"""

bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
loop = GLib.MainLoop()
pending = {}  # id → (invocation, tipo)
next_id = [1]


def send(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def device_prop(path, prop, default=None):
    try:
        r = bus.call_sync("org.bluez", path, "org.freedesktop.DBus.Properties", "Get",
                          GLib.Variant("(ss)", ("org.bluez.Device1", prop)), GLib.VariantType("(v)"),
                          Gio.DBusCallFlags.NONE, 2000, None)
        return r.unpack()[0]
    except GLib.Error:
        return default


def name_of(path):
    return device_prop(path, "Alias", "") or device_prop(path, "Name", "") or path


def ask(invocation, kind, path, **extra):
    i = next_id[0]
    next_id[0] += 1
    pending[i] = (invocation, kind)
    send({"id": i, "type": kind, "device": path, "name": name_of(path), **extra})


def reject(invocation):
    invocation.return_dbus_error("org.bluez.Error.Rejected", "Rejected")


def on_method(conn, sender, path, iface, method, params, invocation):
    args = params.unpack()
    if method == "RequestConfirmation":
        ask(invocation, "confirm", args[0], passkey=args[1])
    elif method == "RequestPinCode":
        ask(invocation, "pin", args[0])
    elif method == "RequestPasskey":
        ask(invocation, "passkey", args[0])
    elif method == "RequestAuthorization":
        ask(invocation, "authorize", args[0])
    elif method == "AuthorizeService":
        # Un dispositivo de confianza se acepta solo; si no, se pregunta
        if device_prop(args[0], "Trusted", False):
            invocation.return_value(None)
        else:
            ask(invocation, "authorize", args[0], service=args[1])
    elif method == "DisplayPasskey":
        send({"type": "display", "device": args[0], "name": name_of(args[0]), "passkey": args[1]})
        invocation.return_value(None)
    elif method == "DisplayPinCode":
        send({"type": "display", "device": args[0], "name": name_of(args[0]), "pin": args[1]})
        invocation.return_value(None)
    elif method == "Cancel":
        for inv, _ in pending.values():
            reject(inv)
        pending.clear()
        send({"type": "cancel"})
        invocation.return_value(None)
    elif method == "Release":
        invocation.return_value(None)
        loop.quit()


def answer(line):
    try:
        msg = json.loads(line)
        inv, kind = pending.pop(msg["id"])
    except (ValueError, KeyError):
        return
    if not msg.get("accept"):
        reject(inv)
    elif kind == "pin":
        inv.return_value(GLib.Variant("(s)", (str(msg.get("value", "")),)))
    elif kind == "passkey":
        try:
            inv.return_value(GLib.Variant("(u)", (int(msg.get("value", 0)),)))
        except ValueError:
            reject(inv)
    else:
        inv.return_value(None)


buf = [""]


def on_stdin(fd, cond):
    if cond & GLib.IOCondition.IN:
        data = sys.stdin.buffer.raw.read(4096) if hasattr(sys.stdin.buffer, "raw") else b""
        if data:
            buf[0] += data.decode("utf-8", "replace")
            while "\n" in buf[0]:
                line, buf[0] = buf[0].split("\n", 1)
                if line.strip():
                    answer(line)
        else:
            loop.quit()
            return False
    if cond & (GLib.IOCondition.HUP | GLib.IOCondition.ERR):
        loop.quit()
        return False
    return True


def main():
    node = Gio.DBusNodeInfo.new_for_xml(XML)
    bus.register_object(AGENT_PATH, node.interfaces[0], on_method, None, None)
    try:
        for method, params in (("RegisterAgent", GLib.Variant("(os)", (AGENT_PATH, CAPABILITY))),
                               ("RequestDefaultAgent", GLib.Variant("(o)", (AGENT_PATH,)))):
            bus.call_sync("org.bluez", "/org/bluez", "org.bluez.AgentManager1", method, params, None,
                          Gio.DBusCallFlags.NONE, 3000, None)
    except GLib.Error as e:
        send({"type": "error", "message": e.message})
        return 1
    send({"type": "ready"})
    GLib.io_add_watch(sys.stdin.fileno(), GLib.PRIORITY_DEFAULT,
                      GLib.IOCondition.IN | GLib.IOCondition.HUP | GLib.IOCondition.ERR, on_stdin)
    loop.run()
    try:
        bus.call_sync("org.bluez", "/org/bluez", "org.bluez.AgentManager1", "UnregisterAgent",
                      GLib.Variant("(o)", (AGENT_PATH,)), None, Gio.DBusCallFlags.NONE, 2000, None)
    except GLib.Error:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
