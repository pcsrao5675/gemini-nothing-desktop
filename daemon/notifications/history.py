"""
Persistent Notification History and SQLite Storage.
Allows querying past notifications, grouping by app, and exposing to topbar plasmoid.
"""

import os
import sqlite3
import time
from typing import List, Dict, Any

DEFAULT_DB_PATH = os.path.expanduser("~/.local/share/nothing-desktop/notifications.db")

class NotificationHistory:
    def __init__(self, db_path: str = DEFAULT_DB_PATH):
        self.db_path = db_path
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        self._init_db()

    def _init_db(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS notifications (
                    id INTEGER PRIMARY KEY,
                    app_name TEXT,
                    app_icon TEXT,
                    summary TEXT,
                    body TEXT,
                    actions TEXT,
                    urgency INTEGER,
                    timestamp REAL,
                    dismissed INTEGER DEFAULT 0
                )
            """)
            conn.commit()

    def add_notification(self, notif_id: int, app_name: str, app_icon: str,
                         summary: str, body: str, actions: list, urgency: int = 1):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO notifications 
                (id, app_name, app_icon, summary, body, actions, urgency, timestamp, dismissed)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)
            """, (notif_id, app_name, app_icon, summary, body, ",".join(actions), urgency, time.time()))
            conn.commit()

    def dismiss(self, notif_id: int):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("UPDATE notifications SET dismissed = 1 WHERE id = ?", (notif_id,))
            conn.commit()

    def clear_all(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("UPDATE notifications SET dismissed = 1")
            conn.commit()

    def get_recent(self, limit: int = 30) -> List[Dict[str, Any]]:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("""
                SELECT * FROM notifications 
                WHERE dismissed = 0 
                ORDER BY timestamp DESC 
                LIMIT ?
            """, (limit,))
            rows = cursor.fetchall()
            return [dict(r) for r in rows]
