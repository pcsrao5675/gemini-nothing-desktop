"""
Nothing OS Notification GUI Renderer.
Uses Gtk 3.0 / Cairo to render sleek borderless Wayland notification banners
with dark glassmorphism, Electric Blue / Red accents, Space Grotesk, and NDot typography.
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib, Pango
import time

class NotificationWindow(Gtk.Window):
    def __init__(self, notif_id: int, app_name: str, app_icon: str,
                 summary: str, body: str, actions: list, urgency: int,
                 config: dict, on_action_cb=None, on_close_cb=None):
        super().__init__(type=Gtk.WindowType.POPUP)
        self.notif_id = notif_id
        self.on_action_cb = on_action_cb
        self.on_close_cb = on_close_cb
        self.urgency = urgency
        self.config = config

        self.set_title(f"NothingNotification-{notif_id}")
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_decorated(False)
        self.set_resizable(False)

        # Enable transparency
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)
        self.set_app_paintable(True)

        self._build_ui(app_name, app_icon, summary, body, actions)
        self._apply_styling()

    def _build_ui(self, app_name, app_icon, summary, body, actions):
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        main_box.set_name("notif-container")
        main_box.set_margin_start(16)
        main_box.set_margin_end(16)
        main_box.set_margin_top(14)
        main_box.set_margin_bottom(14)

        # Header Row
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        
        # Urgency Dot / Accent
        dot_label = Gtk.Label()
        dot_label.set_markup(f"<span foreground='{'#D71921' if self.urgency == 2 else '#4DA3FF'}'>●</span>")
        header_box.pack_start(dot_label, False, False, 0)

        # App Name
        app_label = Gtk.Label(label=app_name.upper())
        app_label.set_name("notif-app-name")
        app_label.set_halign(Gtk.Align.START)
        header_box.pack_start(app_label, True, True, 0)

        # Time label
        time_str = time.strftime("%H:%M")
        time_label = Gtk.Label(label=time_str)
        time_label.set_name("notif-time")
        header_box.pack_end(time_label, False, False, 0)

        # Close button
        close_btn = Gtk.Button(label="✕")
        close_btn.set_name("notif-close-btn")
        close_btn.connect("clicked", lambda b: self.dismiss(reason=2))
        header_box.pack_end(close_btn, False, False, 0)

        main_box.pack_start(header_box, False, False, 0)

        # Content Box
        content_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

        # Optional Icon
        if app_icon:
            icon_theme = Gtk.IconTheme.get_default()
            if icon_theme.has_icon(app_icon):
                icon_img = Gtk.Image.new_from_icon_name(app_icon, Gtk.IconSize.DND)
                content_box.pack_start(icon_img, False, False, 0)

        # Text Column
        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        
        summary_label = Gtk.Label()
        summary_label.set_markup(f"<b>{GLib.markup_escape_text(summary)}</b>")
        summary_label.set_name("notif-summary")
        summary_label.set_halign(Gtk.Align.START)
        summary_label.set_ellipsize(Pango.EllipsizeMode.END)
        text_box.pack_start(summary_label, False, False, 0)

        if body:
            body_label = Gtk.Label()
            body_label.set_markup(GLib.markup_escape_text(body))
            body_label.set_name("notif-body")
            body_label.set_halign(Gtk.Align.START)
            body_label.set_line_wrap(True)
            body_label.set_max_width_chars(38)
            text_box.pack_start(body_label, False, False, 0)

        content_box.pack_start(text_box, True, True, 0)
        main_box.pack_start(content_box, False, False, 0)

        # Action Buttons
        if actions and len(actions) >= 2:
            action_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            for i in range(0, len(actions), 2):
                act_id = actions[i]
                act_label = actions[i+1]
                btn = Gtk.Button(label=act_label)
                btn.set_name("notif-action-btn")
                btn.connect("clicked", lambda b, k=act_id: self._trigger_action(k))
                action_box.pack_start(btn, True, True, 0)
            main_box.pack_start(action_box, False, False, 4)

        self.add(main_box)

    def _apply_styling(self):
        css_provider = Gtk.CssProvider()
        accent = "#D71921" if self.urgency == 2 else self.config.get("visual", {}).get("accent_color", "#4DA3FF")
        bg = "#0B0B0BE6"

        css = f"""
        #notif-container {{
            background-color: {bg};
            border: 1px solid #2B2B2B;
            border-left: 3px solid {accent};
            border-radius: 16px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6);
        }}
        #notif-app-name {{
            font-family: 'Space Grotesk', sans-serif;
            font-size: 11px;
            font-weight: bold;
            color: #888888;
            letter-spacing: 1.5px;
        }}
        #notif-time {{
            font-family: 'NDot 47', monospace;
            font-size: 11px;
            color: #666666;
        }}
        #notif-close-btn {{
            background: transparent;
            border: none;
            color: #888888;
            font-size: 10px;
            padding: 2px 4px;
        }}
        #notif-close-btn:hover {{
            color: #FFFFFF;
        }}
        #notif-summary {{
            font-family: 'Space Grotesk', sans-serif;
            font-size: 13px;
            color: #FFFFFF;
        }}
        #notif-body {{
            font-family: 'Space Grotesk', sans-serif;
            font-size: 12px;
            color: #BBBBBB;
        }}
        #notif-action-btn {{
            background-color: #1A1A1A;
            border: 1px solid #333333;
            border-radius: 8px;
            color: #FFFFFF;
            font-family: 'Space Grotesk', sans-serif;
            font-size: 11px;
            padding: 6px 12px;
        }}
        #notif-action-btn:hover {{
            background-color: {accent};
            color: #000000;
        }}
        """
        css_provider.load_from_data(css.encode())
        context = self.get_style_context()
        context.add_provider_for_screen(Gdk.Screen.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def _trigger_action(self, action_key: str):
        if self.on_action_cb:
            self.on_action_cb(self.notif_id, action_key)
        self.dismiss(reason=3)

    def dismiss(self, reason: int = 2):
        if self.on_close_cb:
            self.on_close_cb(self.notif_id, reason)
        self.destroy()
