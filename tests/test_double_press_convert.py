import pytest

from double_press_convert import convert_text, convert_text_reverse, _LSD_DOUBLES, _LSD_SINGLES


def test_doubles_replacements():
    for src, expected in _LSD_DOUBLES:
        inp = src + src
        assert convert_text(inp) == expected
        # round-trip
        assert convert_text_reverse(expected) == inp


def test_singles_replacements():
    for src, expected in _LSD_SINGLES:
        assert convert_text(src) == expected
        # round-trip
        assert convert_text_reverse(expected) == src


def test_reverse_special_cheh_heh_yeh_isolate():
    assert convert_text_reverse('چھے') == ' \u061B'
    assert convert_text_reverse('چھےک') == 'چھےک'


def test_reverse_seen_seen_word_end():
    assert convert_text_reverse('ہے') == 'ہسس'
    assert convert_text_reverse('ہےا') == 'ہےا'
