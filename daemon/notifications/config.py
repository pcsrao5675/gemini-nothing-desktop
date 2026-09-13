"""
Configuration manager for Nothing OS Notification Daemon.
Loads, manages, and saves per-app rules, DND schedules, and visual parameters.
"""

import os
import json
import datetime

DEFAULT_CONFIG_PATH = os.path.expanduser("~/.config/nothing-desktop/notifications.json")

DEFAULT_CONFIG = {
    "visual": {
        "width": 380,
        "max_popups": 5,
        "timeout_ms": 6000,
        "background_color": "#0B0B0BE8",
        "border_color": "#262626",
        "accent_color": "#4DA3FF",
        "font_family": "Space Grotesk",
        "font_dots": "NDot 47",
        "corner_radius": 16,
        "show_icon": True,
        "position": "top_right",
        "margin_x": 24,
        "margin_y": 48
    },
    "dnd": {
        "enabled": False,
        "schedule_enabled": False,
        "start_time": "22:00",
        "end_time": "07:00",
        "allow_critical": True
    },
    "apps": {
        "default": {
            "urgency_override": None,
            "silent": False,
            "accent_color": "#4DA3FF"
        },
        "Spotify": {
            "timeout_ms": 4000,
            "accent_color": "#1DB954"
        },
        "Slack": {
            "accent_color": "#E01E5A"
        },
        "Discord": {
            "accent_color": "#5865F2"
        }
    }
}

class NotificationConfig:
    def __init__(self, path: str = DEFAULT_CONFIG_PATH):
        self.path = path
        self.data = self._load()

    def _load(self) -> dict:
        if os.path.exists(self.path):
            try:
                with open(self.path, "r", encoding="utf-8") as f:
                    user_cfg = json.load(f)
                    cfg = DEFAULT_CONFIG.copy()
                    for k, v in user_cfg.items():
                        if isinstance(v, dict) and k in cfg:
                            cfg[k].update(v)
                        else:
                            cfg[k] = v
                    return cfg
            except Exception:
                pass
        return DEFAULT_CONFIG.copy()

    def save(self):
        try:
            os.makedirs(os.path.dirname(self.path), exist_ok=True)
            with open(self.path, "w", encoding="utf-8") as f:
                json.dump(self.data, f, indent=2)
        except Exception as e:
            print(f"[NotifConfig] Failed to save config: {e}")

    def is_dnd_active(self) -> bool:
        dnd = self.data.get("dnd", {})
        if dnd.get("enabled", False):
            return True
        if dnd.get("schedule_enabled", False):
            try:
                now = datetime.datetime.now().time()
                sh, sm = map(int, dnd.get("start_time", "22:00").split(":"))
                eh, em = map(int, dnd.get("end_time", "07:00").split(":"))
                start = datetime.time(sh, sm)
                end = datetime.time(eh, em)
                if start <= end:
                    return start <= now <= end
                else: # Crosses midnight
                    return now >= start or now <= end
            except Exception:
                pass
        return False

    def get_app_rule(self, app_name: str) -> dict:
        apps = self.data.get("apps", {})
        return apps.get(app_name, apps.get("default", {}))
