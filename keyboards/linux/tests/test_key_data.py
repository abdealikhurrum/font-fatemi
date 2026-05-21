"""Tests for LSD keyboard layout data."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from lsd_ibus.key_data import (
    NORMAL_LAYER, SHIFT_LAYER, ALT_LAYER, secondary_for
)


def test_all_standard_lsd_chars_reachable():
    """Every character in the standard LSD letter set must be in normal or shift layer."""
    standard = set("ضصثقفغعهخحجشسيبلاتنمكطئءؤرىةوزدظ")
    mapped = set(NORMAL_LAYER.values()) | set(SHIFT_LAYER.values())
    missing = standard - mapped
    assert not missing, f"LSD chars not reachable from any layer: {missing}"


def test_official_double_press_rules():
    """All seven official double-press rules from lsd.kmn must fire correctly."""
    rules = {
        "س": "ے",
        "ض": "ٹ",
        "ط": "ں",
        "ظ": "ہ",
        "ح": "چ",
        "ث": "پ",
        "ك": "گ",
    }
    for primary, expected in rules.items():
        got = secondary_for(primary)
        assert got == expected, f"Double-press {primary!r}: expected {expected!r}, got {got!r}"


def test_extended_double_press_rules():
    """Extended double-press secondaries must also be correct."""
    rules = {
        "ا": "اٰ",
        "ه": "ھ",
        "ي": "ئ",
        "ر": "ڑ",
        "د": "ڈ",
        "ة": "ۃ",
        "ج": "چھے",
    }
    for primary, expected in rules.items():
        got = secondary_for(primary)
        assert got == expected, f"Double-press {primary!r}: expected {expected!r}, got {got!r}"


def test_secondary_for_unmapped_char_returns_none():
    assert secondary_for("ب") is None
    assert secondary_for("ل") is None
    assert secondary_for("") is None


def test_digits_are_eastern_arabic_indic():
    """Digit keys 1–0 must produce Eastern Arabic-Indic numerals."""
    expected = {
        10: "١", 11: "٢", 12: "٣", 13: "٤", 14: "٥",
        15: "٦", 16: "٧", 17: "٨", 18: "٩", 19: "٠",
    }
    for kc, char in expected.items():
        assert NORMAL_LAYER.get(kc) == char, (
            f"X11 keycode {kc}: expected {char!r}, got {NORMAL_LAYER.get(kc)!r}"
        )


def test_no_duplicate_keycodes_in_normal_layer():
    """Every X11 keycode in NORMAL_LAYER must appear exactly once."""
    seen: dict[int, str] = {}
    for kc, ch in NORMAL_LAYER.items():
        assert kc not in seen, (
            f"Keycode {kc} mapped twice: {seen[kc]!r} and {ch!r}"
        )
        seen[kc] = ch


def test_comma_and_period_mapping():
    assert NORMAL_LAYER[59] == "،", "Comma key should produce Arabic comma ،"
    assert SHIFT_LAYER.get(61) == "؟", "/+Shift should produce Arabic question mark ؟"


def test_tatweel_accessible():
    assert NORMAL_LAYER[49] == "ـ", "Backtick key should produce tatweel ـ"
