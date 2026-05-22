import pytest

from double_press_convert import convert_text, _LSD_DOUBLES, _LSD_SINGLES


def test_doubles_replacements():
    for src, expected in _LSD_DOUBLES:
        inp = src + src
        assert convert_text(inp) == expected


def test_singles_replacements():
    for src, expected in _LSD_SINGLES:
        assert convert_text(src) == expected
