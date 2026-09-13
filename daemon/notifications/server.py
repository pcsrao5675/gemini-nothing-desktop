#!/usr/bin/env python3
"""
Nothing OS Default System Notification Server.
Implements org.freedesktop.Notifications specification over D-Bus with Nothing OS styling,
per-app rules, DND scheduling, and persistent history tracking.
"""

import sys
import os
import dbus
import dbus.service
import dbus.mainloop.glib

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
from gi.repository import GLib, Gdk

# Ensure current directory is in sys.path when executed directly
if __package__ is None or __package__ == "":
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from config import NotificationConfig
    from history import NotificationHistory
    from renderer import NotificationWindow
else:
    from .config import NotificationConfig
    from .history import NotificationHistory
    from .renderer import NotificationWindow

INTERFACE = "org.freedesktop.Notifications"
PATH = "/org/freedesktop/Notifications"

class NothingNotificationServer(dbus.service.Object):
    def __init__(self, bus, config: NotificationConfig, history: NotificationHistory):
        self.bus = bus
        self.config = config
        self.history = history
        self.next_id = 1
        self.active_popups = {} # id -> NotificationWindow

        super().__init__(bus, PATH)

    @dbus.service.method(INTERFACE, in_signature="", out_signature="as")
    def GetCapabilities(self):
        return [
            "actions",
            "body",
            "body-hyperlinks",
            "body-markup",
            "icon-static",
            "persistence"
        ]

    @dbus.service.method(INTERFACE, in_signature="", out_signature="ssss")
    def GetServerInformation(self):
        return ("NothingNotificationDaemon", "NothingOS", "1.0", "1.2")

    @dbus.service.method(INTERFACE, in_signature="susssasa{sv}i", out_signature="u")
    def Notify(self, app_name, replaces_id, app_icon, summary, body, actions, hints, timeout):
        notif_id = int(replaces_id) if replaces_id > 0 else self.next_id
        if replaces_id == 0:
            self.next_id += 1

        urgency = 1
        if "urgency" in hints:
            try:
                urgency = int(hints["urgency"])
            except Exception:
                pass

        # Per-app rule check
        app_rule = self.config.get_app_rule(str(app_name))
        if app_rule.get("urgency_override") is not None:
            urgency = app_rule["urgency_override"]

        # Check Do Not Disturb
        is_dnd = self.config.is_dnd_active()
        if is_dnd and urgency < 2 and not self.config.data.get("dnd", {}).get("allow_critical", True):
            # Suppress popup but record to history
            self.history.add_notification(notif_id, str(app_name), str(app_icon),
                                          str(summary), str(body), list(actions), urgency)
            return notif_id

        # Record to history store
        self.history.add_notification(notif_id, str(app_name), str(app_icon),
                                      str(summary), str(body), list(actions), urgency)

        # Close existing if replacing
        if notif_id in self.active_popups:
            try:
                self.active_popups[notif_id].destroy()
            except Exception:
                pass
            del self.active_popups[notif_id]

        # Calculate timeout
        effective_timeout = timeout
        if effective_timeout <= 0:
            effective_timeout = app_rule.get("timeout_ms", self.config.data.get("visual", {}).get("timeout_ms", 6000))

        # Render popup UI
        def _on_action(nid, act_key):
            self.ActionInvoked(nid, act_key)

        def _on_close(nid, reason):
            if nid in self.active_popups:
                del self.active_popups[nid]
            self.NotificationClosed(nid, reason)
            self._reposition_popups()

        popup = NotificationWindow(
            notif_id=notif_id,
            app_name=str(app_name),
            app_icon=str(app_icon),
            summary=str(summary),
            body=str(body),
            actions=list(actions),
            urgency=urgency,
            config=self.config.data,
            on_action_cb=_on_action,
            on_close_cb=_on_close
        )

        self.active_popups[notif_id] = popup
        popup.show_all()
        self._reposition_popups()

        # Auto-dismiss timer
        if effective_timeout > 0:
            GLib.timeout_add(effective_timeout, lambda nid=notif_id: self._auto_close(nid))

        return notif_id

    def _auto_close(self, notif_id):
        if notif_id in self.active_popups:
            self.active_popups[notif_id].dismiss(reason=1) # 1 = expired
        return False

    def _reposition_popups(self):
        screen = Gdk.Screen.get_default()
        if not screen: return
        screen_w = screen.get_width()
        margin_x = self.config.data.get("visual", {}).get("margin_x", 24)
        curr_y = self.config.data.get("visual", {}).get("margin_y", 54)

        for nid, win in list(self.active_popups.items()):
            w, h = win.get_size()
            win.move(screen_w - w - margin_x, curr_y)
            curr_y += h + 12

    @dbus.service.method(INTERFACE, in_signature="u", out_signature="")
    def CloseNotification(self, notif_id):
        if notif_id in self.active_popups:
            self.active_popups[notif_id].dismiss(reason=3) # 3 = closed via API

    @dbus.service.signal(INTERFACE, signature="us")
    def ActionInvoked(self, notif_id, action_key):
        pass

    @dbus.service.signal(INTERFACE, signature="uu")
    def NotificationClosed(self, notif_id, reason):
        pass

def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()

    # Claim D-Bus bus name
    flags = dbus.bus.NAME_FLAG_REPLACE_EXISTING | dbus.bus.NAME_FLAG_DO_NOT_QUEUE
    request_result = bus.request_name(INTERFACE, flags)
    print(f"[NothingNotificationDaemon] Bus claim request status: {request_result}")

    cfg = NotificationConfig()
    hist = NotificationHistory()
    server = NothingNotificationServer(bus, cfg, hist)

    print("[NothingNotificationDaemon] Successfully started and listening for system notifications.")
    loop = GLib.MainLoop()
    try:
        loop.run()
    except KeyboardInterrupt:
        print("[NothingNotificationDaemon] Shutting down.")

if __name__ == "__main__":
    main()
