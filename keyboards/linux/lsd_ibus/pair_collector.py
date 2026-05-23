"""
LSD corpus collector for Linux.

Schema is identical to iOS/macOS/Android/Windows so data from all platforms
can be merged into a single corpus.

Database path: ~/.local/share/lsd-keyboard/lsd_pairs.sqlite
"""

from __future__ import annotations

import sqlite3
import time
from pathlib import Path

_DEFAULT_DB = Path.home() / ".local" / "share" / "lsd-keyboard" / "lsd_pairs.sqlite"

_SCHEMA = """
CREATE TABLE IF NOT EXISTS pairs (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    lsd_input    TEXT    NOT NULL,
    roman_output TEXT    NOT NULL,
    source       TEXT    NOT NULL DEFAULT 'correction',
    created_at   REAL    NOT NULL,
    contributed  INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_contributed ON pairs (contributed);
"""


class PairCollector:
    def __init__(self, db_path: Path = _DEFAULT_DB) -> None:
        db_path.parent.mkdir(parents=True, exist_ok=True)
        self._conn = sqlite3.connect(str(db_path), check_same_thread=False)
        self._conn.executescript(_SCHEMA)
        self._conn.commit()

    # ------------------------------------------------------------------
    # Recording

    def record_accepted(self, lsd: str, roman: str) -> None:
        self._insert(lsd, roman, "accepted")

    def record_correction(self, lsd: str, corrected_roman: str) -> None:
        self._insert(lsd, corrected_roman, "correction")

    def record_double_press(self, primary: str, secondary: str) -> None:
        # lsd_input = secondary (what was inserted); roman_output = primary pressed
        # Matches the convention used on iOS/macOS/Android.
        self._insert(secondary, primary, "double_press_linux")

    # ------------------------------------------------------------------
    # Queries

    def pending_count(self) -> int:
        row = self._conn.execute(
            "SELECT COUNT(*) FROM pairs WHERE contributed = 0"
        ).fetchone()
        return row[0] if row else 0

    def total_count(self) -> int:
        row = self._conn.execute("SELECT COUNT(*) FROM pairs").fetchone()
        return row[0] if row else 0

    def fetch_pending(self, limit: int = 2000) -> list[tuple[int, str, str]]:
        return self._conn.execute(
            "SELECT id, lsd_input, roman_output FROM pairs "
            "WHERE contributed = 0 LIMIT ?",
            (limit,),
        ).fetchall()

    def mark_contributed(self, ids: list[int]) -> None:
        if not ids:
            return
        placeholders = ",".join("?" * len(ids))
        self._conn.execute(
            f"UPDATE pairs SET contributed = 1 WHERE id IN ({placeholders})", ids
        )
        self._conn.commit()

    def delete_all(self) -> None:
        self._conn.execute("DELETE FROM pairs")
        self._conn.commit()

    # ------------------------------------------------------------------
    # Helpers

    def _insert(self, lsd: str, roman: str, source: str) -> None:
        self._conn.execute(
            "INSERT INTO pairs (lsd_input, roman_output, source, created_at) "
            "VALUES (?, ?, ?, ?)",
            (lsd, roman, source, time.time()),
        )
        self._conn.commit()

    def close(self) -> None:
        self._conn.close()
