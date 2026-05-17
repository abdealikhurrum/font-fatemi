import UIKit

// Centralised adaptive colour palette.
// Every UIColor here resolves automatically when the trait collection changes —
// no traitCollectionDidChange overrides required for backgroundColor.
// Core Graphics drawing (KeyCalloutView) must call .resolvedColor(with: traitCollection).

enum KeyboardColors {

    // MARK: - Backgrounds

    static let background = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.137, green: 0.137, blue: 0.145, alpha: 1)   // #232325
            : UIColor(red: 0.812, green: 0.820, blue: 0.843, alpha: 1)   // #CFD1D7
    }

    static let predictiveBar = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1)   // #1C1C1E
            : UIColor(red: 0.839, green: 0.847, blue: 0.863, alpha: 1)   // #D6D8DC
    }

    static let separator = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.28, alpha: 1)
            : UIColor(white: 0.63, alpha: 1)
    }

    // MARK: - Key backgrounds

    static let characterKey = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.420, green: 0.420, blue: 0.439, alpha: 1)   // #6B6B70
            : .white
    }

    static let specialKey = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.165, green: 0.165, blue: 0.176, alpha: 1)   // #2A2A2D
            : UIColor(red: 0.651, green: 0.675, blue: 0.718, alpha: 1)   // #A6ACB7
    }

    // Pressed state: character keys darken to match special key hue
    static let pressedKey = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.239, green: 0.239, blue: 0.255, alpha: 1)
            : UIColor(red: 0.651, green: 0.675, blue: 0.718, alpha: 1)
    }

    // MARK: - Shift locked state (inverted for emphasis)

    static let shiftLockedBackground = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(white: 0.85, alpha: 1)
            : UIColor(white: 0.22, alpha: 1)
    }

    static let shiftLockedText = UIColor { tc in
        tc.userInterfaceStyle == .dark ? .black : .white
    }

    // MARK: - Callout & popup

    static let calloutBubble = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.310, green: 0.310, blue: 0.325, alpha: 1)
            : UIColor(white: 0.20, alpha: 1)
    }

    static let popup = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.255, green: 0.255, blue: 0.267, alpha: 1)
            : UIColor(white: 0.96, alpha: 1)
    }
}
