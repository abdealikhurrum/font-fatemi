import Foundation

// Standard QWERTY layout used when the user switches to the Latin layer.
// The bottom-row "ع" key (ABC) returns to the prior Arabic layer;
// long-pressing it calls advanceToNextInputMode() via longPressType: .globe.

enum LatinLayoutData {

    static let lowerLayer = KeyboardLayer(id: "latin_lower", rows: [
        [
            KeyData("q"), KeyData("w"), KeyData("e"), KeyData("r"), KeyData("t"),
            KeyData("y"), KeyData("u"), KeyData("i"), KeyData("o"), KeyData("p"),
        ],
        [
            KeyData("a"), KeyData("s"), KeyData("d"), KeyData("f"), KeyData("g"),
            KeyData("h"), KeyData("j"), KeyData("k"), KeyData("l"),
        ],
        [
            KeyData("⇧", type: .shift,     width: .wide),
            KeyData("z"), KeyData("x"), KeyData("c"), KeyData("v"),
            KeyData("b"), KeyData("n"), KeyData("m"),
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        [
            KeyData("ع",   type: .abc,     width: .fixed(80), longPressType: .globe),
            KeyData(" ",   alternates: ["\u{00A0}", "\u{200C}", " "],
                           type: .space,   width: .flexible),
            KeyData("١٢٣", type: .numeric, width: .fixed(44)),
            KeyData("↵",   type: .enter,   width: .fixed(80)),
        ],
    ])

    static let upperLayer = KeyboardLayer(id: "latin_upper", rows: [
        [
            KeyData("Q"), KeyData("W"), KeyData("E"), KeyData("R"), KeyData("T"),
            KeyData("Y"), KeyData("U"), KeyData("I"), KeyData("O"), KeyData("P"),
        ],
        [
            KeyData("A"), KeyData("S"), KeyData("D"), KeyData("F"), KeyData("G"),
            KeyData("H"), KeyData("J"), KeyData("K"), KeyData("L"),
        ],
        [
            KeyData("⬆", type: .shift,     width: .wide),
            KeyData("Z"), KeyData("X"), KeyData("C"), KeyData("V"),
            KeyData("B"), KeyData("N"), KeyData("M"),
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        [
            KeyData("ع",   type: .abc,     width: .fixed(80), longPressType: .globe),
            KeyData(" ",   alternates: ["\u{00A0}", "\u{200C}", " "],
                           type: .space,   width: .flexible),
            KeyData("١٢٣", type: .numeric, width: .fixed(44)),
            KeyData("↵",   type: .enter,   width: .fixed(80)),
        ],
    ])
}
