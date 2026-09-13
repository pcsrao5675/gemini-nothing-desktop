#!/usr/bin/env python3
"""
Local helper daemon for Gemini Floating Assistant.
Binds strictly to 127.0.0.1:8765 (localhost only).
Coordinates fast window hiding, desktop capture via spectacle, window restoration,
and tracks whether the assistant is currently active for desktop widget effects.
"""

import os
import sys
import time
import shutil
import subprocess
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
import socket

HOST = "127.0.0.1"
PORT = 8765
CAPTURE_PATH = "/tmp/gemini_auto_capture.png"
ACTIVE_FILE = "/tmp/gemini_active"
SOCKET_PATH = "/tmp/gemini_assistant.sock"
BRAVE_PROFILE_DIR = os.path.expanduser("~/.local/share/gemini-assistant/brave-profile")

_socket_clients = []
_socket_lock = threading.Lock()

def broadcast_state(val: bool, cmd: str = ""):
    """Broadcasts active state changes over the Unix domain socket push channel."""
    msg = f"{'1' if val else '0'}:{cmd}\n".encode("utf-8")
    with _socket_lock:
        dead = []
        for client in _socket_clients:
            try:
                client.sendall(msg)
            except Exception:
                dead.append(client)
        for d in dead:
            _socket_clients.remove(d)

def start_socket_server():
    """Listens on /tmp/gemini_assistant.sock for push subscribers."""
    if os.path.exists(SOCKET_PATH):
        try:
            os.remove(SOCKET_PATH)
        except OSError:
            pass
    try:
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.bind(SOCKET_PATH)
        sock.listen(10)
        os.chmod(SOCKET_PATH, 0o666)
        while True:
            client, _ = sock.accept()
            # Send current state on connect
            is_active = get_active_status()
            try:
                client.sendall(f"{is_active}:\n".encode("utf-8"))
            except Exception:
                pass
            with _socket_lock:
                _socket_clients.append(client)
    except Exception as e:
        print(f"[ScreenshotServer] Socket server error: {e}", file=sys.stderr)

def set_active_state(val: bool, cmd: str = ""):
    try:
        with open(ACTIVE_FILE, "w") as f:
            f.write("1" if val else "0")
    except Exception as e:
        print(f"[ScreenshotServer] Error writing active state: {e}", file=sys.stderr)
    broadcast_state(val, cmd)

def monitor_brave_process():
    """Background monitor to reset active state if the assistant is closed/killed."""
    while True:
        try:
            res = subprocess.run(
                ["pgrep", "-f", f"user-data-dir={BRAVE_PROFILE_DIR}"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            if res.returncode != 0:
                set_active_state(False)
        except Exception:
            pass
        time.sleep(1.0)

def run_kwin_script(js_code, name):
    """Executes a temporary KWin 6 script via DBus."""
    path = f"/tmp/{name}.js"
    try:
        with open(path, "w") as f:
            f.write(js_code)
        proc = subprocess.run(
            ["qdbus6", "org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting.loadScript", path, name],
            capture_output=True, text=True, timeout=1.0
        )
        run_id = proc.stdout.strip()
        if run_id and run_id != "-1":
            subprocess.run(["qdbus6", "org.kde.KWin", f"/Scripting/Script{run_id}", "org.kde.kwin.Script.run"], timeout=1.0)
            time.sleep(0.05)
            subprocess.run(["qdbus6", "org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting.unloadScript", name], timeout=1.0)
    except Exception as e:
        print(f"[ScreenshotServer] KWin script error ({name}): {e}", file=sys.stderr)
    finally:
        if os.path.exists(path):
            try:
                os.remove(path)
            except OSError:
                pass

def hide_gemini():
    """Minimizes the Gemini assistant window so it does not block the desktop screenshot."""
    script = """
    var wins = workspace.windowList();
    for (var i = 0; i < wins.length; i++) {
        var w = wins[i];
        if (w.resourceClass && (w.resourceClass.indexOf("gemini.google.com") !== -1 || w.resourceClass === "gemini-floating-assistant")) {
            w.minimized = true;
            break;
        }
    }
    """
    run_kwin_script(script, "gemini_srv_hide")

def restore_gemini():
    """Restores and refocuses the Gemini assistant window."""
    script = """
    var wins = workspace.windowList();
    for (var i = 0; i < wins.length; i++) {
        var w = wins[i];
        if (w.resourceClass && (w.resourceClass.indexOf("gemini.google.com") !== -1 || w.resourceClass === "gemini-floating-assistant")) {
            w.minimized = false;
            workspace.activeWindow = w;
            break;
        }
    }
    """
    run_kwin_script(script, "gemini_srv_restore")

def toggle_maximize():
    """Toggles window fullscreen / floating size for Gemini."""
    script = """
    var wins = workspace.windowList();
    for (var i = 0; i < wins.length; i++) {
        var w = wins[i];
        if (w.resourceClass && (w.resourceClass.indexOf("gemini.google.com") !== -1 || w.resourceClass === "gemini-floating-assistant")) {
            w.fullScreen = !w.fullScreen;
            workspace.activeWindow = w;
            break;
        }
    }
    """
    run_kwin_script(script, "gemini_srv_toggle_max")

def get_active_status() -> str:
    """Reads and returns the active state string ('1' or '0')."""
    is_active = "0"
    if os.path.exists(ACTIVE_FILE):
        try:
            with open(ACTIVE_FILE, "r") as f:
                is_active = f.read().strip()
        except Exception:
            pass
    return is_active

def take_screenshot(output_path: str = CAPTURE_PATH) -> bool:
    """Coordinates Spectacle desktop capture while temporarily hiding Gemini."""
    if not shutil.which("spectacle"):
        return False
    try:
        if os.path.exists(output_path):
            try:
                os.remove(output_path)
            except OSError:
                pass

        hide_gemini()
        time.sleep(0.04)

        subprocess.run(
            ["spectacle", "-b", "-n", "-o", output_path],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            timeout=4.0
        )

        restore_gemini()
        set_active_state(True)
        return os.path.exists(output_path)
    except Exception as e:
        print(f"[ScreenshotServer] Capture error: {e}", file=sys.stderr)
        restore_gemini()
        return False

def get_gemini_maximized_state():
    """Checks whether the Gemini window is currently maximized."""
    # We can query or toggle via script
    pass

class ScreenshotHandler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def do_GET(self):
        if self.path == "/screenshot":
            # 1. Verify spectacle is installed
            if not shutil.which("spectacle"):
                self.send_response(503)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(b'{"error": "spectacle not installed on system"}')
                return

            try:
                ok = take_screenshot(CAPTURE_PATH)
                if ok and os.path.exists(CAPTURE_PATH):
                    with open(CAPTURE_PATH, "rb") as f:
                        img_bytes = f.read()

                    self.send_response(200)
                    self.send_header("Content-Type", "image/png")
                    self.send_header("Access-Control-Allow-Origin", "*")
                    self.send_header("Content-Length", str(len(img_bytes)))
                    self.end_headers()
                    self.wfile.write(img_bytes)
                    return
                else:
                    raise FileNotFoundError("Captured image file not created")

            except Exception as e:
                print(f"[ScreenshotServer] Capture error: {e}", file=sys.stderr)
                restore_gemini()
                self.send_response(500)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(f'{{"error": "{str(e)}"}}'.encode("utf-8"))

        elif self.path.startswith("/active"):
            if "val=1" in self.path:
                set_active_state(True)
            elif "val=0" in self.path:
                set_active_state(False)

            is_active = get_active_status()

            # Check if there is a pending trigger command
            trigger_cmd = ""
            trigger_file = "/tmp/gemini_island_trigger"
            if "trigger=" in self.path:
                import urllib.parse
                parsed = urllib.parse.urlparse(self.path)
                params = urllib.parse.parse_qs(parsed.query)
                if "trigger" in params:
                    with open(trigger_file, "w") as f:
                        f.write(params["trigger"][0])
            elif os.path.exists(trigger_file):
                try:
                    with open(trigger_file, "r") as f:
                        trigger_cmd = f.read().strip()
                    os.remove(trigger_file)
                except Exception:
                    pass

            response_payload = f"{is_active}:{trigger_cmd}" if trigger_cmd else is_active
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(response_payload.encode("utf-8"))

        elif self.path.startswith("/close") or self.path.startswith("/hide"):
            hide_gemini()
            set_active_state(False)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(b'{"status": "ok"}')

        elif self.path.startswith("/maximize"):
            toggle_maximize()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(b'{"status": "ok"}')

        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        self.do_GET()

    def log_message(self, format, *args):
        pass

def run():
    set_active_state(False)
    threading.Thread(target=start_socket_server, daemon=True).start()
    threading.Thread(target=monitor_brave_process, daemon=True).start()
    server = HTTPServer((HOST, PORT), ScreenshotHandler)
    print(f"[ScreenshotServer] Listening on http://{HOST}:{PORT}")
    server.serve_forever()

if __name__ == "__main__":
    run()
