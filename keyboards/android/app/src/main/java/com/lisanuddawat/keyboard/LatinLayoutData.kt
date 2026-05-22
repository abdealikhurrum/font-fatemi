package com.lisanuddawat.keyboard

object LatinLayoutData {

    // ⇧ = unshifted,  ⬆ = shifted/caps (different glyph so KeyButton can render state)
    val lowerLayer = KeyboardLayer("latin_lower", listOf(
        listOf(
            KeyData("q"), KeyData("w"), KeyData("e"), KeyData("r"), KeyData("t"),
            KeyData("y"), KeyData("u"), KeyData("i"), KeyData("o"), KeyData("p"),
        ),
        listOf(
            KeyData("a"), KeyData("s"), KeyData("d"), KeyData("f"), KeyData("g"),
            KeyData("h"), KeyData("j"), KeyData("k"), KeyData("l"),
        ),
        listOf(
            KeyData("⇧",  type = KeyType.SHIFT,     width = KeyWidth.Wide),
            KeyData("z"),  KeyData("x"), KeyData("c"), KeyData("v"),
            KeyData("b"),  KeyData("n"), KeyData("m"),
            KeyData("⌫",  type = KeyType.BACKSPACE,  width = KeyWidth.Wide),
        ),
        listOf(
            KeyData("ع",   type = KeyType.ABC,     width = KeyWidth.Fixed(80f),
                           longPressType = KeyType.GLOBE),
            KeyData(" ",   type = KeyType.SPACE,   width = KeyWidth.Flexible,
                           alternates = listOf(" ", "‌", " ")),
            KeyData("١٢٣", type = KeyType.NUMERIC, width = KeyWidth.Fixed(44f)),
            KeyData("↵",   type = KeyType.ENTER,   width = KeyWidth.Fixed(80f)),
        ),
    ))

    val upperLayer = KeyboardLayer("latin_upper", listOf(
        listOf(
            KeyData("Q"), KeyData("W"), KeyData("E"), KeyData("R"), KeyData("T"),
            KeyData("Y"), KeyData("U"), KeyData("I"), KeyData("O"), KeyData("P"),
        ),
        listOf(
            KeyData("A"), KeyData("S"), KeyData("D"), KeyData("F"), KeyData("G"),
            KeyData("H"), KeyData("J"), KeyData("K"), KeyData("L"),
        ),
        listOf(
            KeyData("⬆",  type = KeyType.SHIFT,     width = KeyWidth.Wide),
            KeyData("Z"),  KeyData("X"), KeyData("C"), KeyData("V"),
            KeyData("B"),  KeyData("N"), KeyData("M"),
            KeyData("⌫",  type = KeyType.BACKSPACE,  width = KeyWidth.Wide),
        ),
        listOf(
            KeyData("ع",   type = KeyType.ABC,     width = KeyWidth.Fixed(80f),
                           longPressType = KeyType.GLOBE),
            KeyData(" ",   type = KeyType.SPACE,   width = KeyWidth.Flexible,
                           alternates = listOf(" ", "‌", " ")),
            KeyData("١٢٣", type = KeyType.NUMERIC, width = KeyWidth.Fixed(44f)),
            KeyData("↵",   type = KeyType.ENTER,   width = KeyWidth.Fixed(80f)),
        ),
    ))
}
