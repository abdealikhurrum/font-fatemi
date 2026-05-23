"""
LSD IBus engine — Lisan ud Dawat input method for Linux.

Inherits from IBus.Engine and handles:
  - Key-position-based character mapping (3 layers: normal / shift / alt)
  - Double-press substitution with configurable timeout window
  - Corpus logging via PairCollector (same SQLite schema as other platforms)
"""

from __future__ import annotations

import time
import gi

gi.require_version("IBus", "1.0")
from gi.repository import IBus, GLib  # noqa: E402

from .key_data import NORMAL_LAYER, SHIFT_LAYER, ALT_LAYER, secondary_for
from .pair_collector import PairCollector

# Seconds within which a repeated key is treated as a double-press.
# 500 ms matches the default on iOS and macOS.
DOUBLE_PRESS_WINDOW: float = 0.5


class LSDEngine(IBus.Engine):
    __gtype_name__ = "LSDEngine"

    def __init__(self) -> None:
        super().__init__()
        self._collector = PairCollector()
        self._last_char: str = ""
        self._last_time: float = 0.0

    # ------------------------------------------------------------------
    # IBus.Engine overrides

    def do_process_key_event(self, keyval: int, keycode: int, state: int) -> bool:
        # Ignore key-release events.
        if state & IBus.ModifierType.RELEASE_MASK:
            return False

        shift = bool(state & IBus.ModifierType.SHIFT_MASK)
        alt   = bool(state & IBus.ModifierType.MOD1_MASK)
        ctrl  = bool(state & IBus.ModifierType.CONTROL_MASK)

        # Pass Ctrl+* shortcuts straight through.
        if ctrl:
            return False

        # Backspace, space, enter, tab, escape all break a pending double-press
        # and are handled by the application as normal.
        if keyval in (
            IBus.KEY_BackSpace,
            IBus.KEY_space,
            IBus.KEY_Return,
            IBus.KEY_KP_Enter,
            IBus.KEY_Tab,
            IBus.KEY_Escape,
        ):
            self._reset()
            return False

        char = _map_key(keycode, shift, alt)
        if char is None:
            self._reset()
            return False

        # Double-press detection: same char pressed twice within the window.
        now = time.monotonic()
        if char == self._last_char and (now - self._last_time) <= DOUBLE_PRESS_WINDOW:
            sec = secondary_for(char)
            if sec:
                # Delete the primary character that was committed on the first press.
                self.delete_surrounding_text(1, 0)
                self.commit_text(IBus.Text.new_from_string(sec))
                self._collector.record_double_press(primary=char, secondary=sec)
                self._reset()
                return True

        self._last_char = char
        self._last_time = now
        self.commit_text(IBus.Text.new_from_string(char))
        return True

    def do_focus_in(self) -> None:
        self._reset()

    def do_focus_out(self) -> None:
        self._reset()

    def do_reset(self) -> None:
        self._reset()

    # ------------------------------------------------------------------
    # Internal helpers

    def _reset(self) -> None:
        self._last_char = ""
        self._last_time = 0.0


def _map_key(keycode: int, shift: bool, alt: bool) -> str | None:
    """Return the LSD character for an X11 hardware keycode + modifier combination."""
    if alt:
        return ALT_LAYER.get(keycode)
    if shift:
        return SHIFT_LAYER.get(keycode)
    return NORMAL_LAYER.get(keycode)
