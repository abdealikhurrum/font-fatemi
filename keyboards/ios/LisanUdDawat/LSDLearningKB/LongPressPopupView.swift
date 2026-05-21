import UIKit

// Popup that appears above a key on long-press, showing alternate characters.
// Dismiss by sliding to a character and releasing, or tap outside to cancel.

protocol LongPressPopupDelegate: AnyObject {
    func popupDidSelect(_ character: String)
    func popupDidCancel()
}

final class LongPressPopupView: UIView {

    weak var delegate: LongPressPopupDelegate?

    private let keySize: CGSize
    private let alternates: [String]
    private var buttons: [UIButton] = []
    private var selectedIndex: Int? = nil
    var selectedCharacter: String? { selectedIndex.map { alternates[$0] } }

    private static let padding: CGFloat = 6
    private static let itemSpacing: CGFloat = 4
    private static let cornerRadius: CGFloat = 10
    private static let font = UIFont(name: "FatemiMaqala", size: 20) ?? UIFont.systemFont(ofSize: 20)

    init(alternates: [String], keySize: CGSize) {
        self.alternates = alternates
        self.keySize = keySize
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 2)

        let count = CGFloat(alternates.count)
        let p = LongPressPopupView.padding
        let sp = LongPressPopupView.itemSpacing
        let itemW = min(keySize.width, 52)   // cap so space-bar popup isn't enormous
        let itemH = keySize.height
        let totalW = count * itemW + (count - 1) * sp + 2 * p
        let totalH = itemH + 2 * p

        let bg = UIView(frame: CGRect(x: 0, y: 0, width: totalW, height: totalH))
        bg.backgroundColor = KeyboardColors.popup
        bg.layer.cornerRadius = LongPressPopupView.cornerRadius
        bg.layer.masksToBounds = true
        addSubview(bg)

        for (i, alt) in alternates.enumerated() {
            let x = p + CGFloat(i) * (itemW + sp)
            let btn = UIButton(frame: CGRect(x: x, y: p, width: itemW, height: itemH))
            let title = visibleTitle(alt)
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(.label, for: .normal)
            btn.setTitleColor(.white, for: .selected)
            btn.titleLabel?.font = isLabel(title)
                ? UIFont.systemFont(ofSize: 11, weight: .medium)
                : LongPressPopupView.font
            btn.titleLabel?.adjustsFontSizeToFitWidth = true
            btn.titleLabel?.minimumScaleFactor = 0.7
            btn.titleLabel?.textAlignment = .center
            btn.layer.cornerRadius = 8
            btn.tag = i
            bg.addSubview(btn)
            buttons.append(btn)
        }

        frame = CGRect(x: 0, y: 0, width: totalW, height: totalH)
    }

    // MARK: - Interaction

    // Call from the parent's gesture recogniser location (converted into this view's coordinate space).
    func updateSelection(at point: CGPoint) {
        // Expand hit zone vertically so gesture can be initiated from key area
        let expanded = bounds.insetBy(dx: -20, dy: -60)
        guard expanded.contains(point) else {
            clearSelection()
            return
        }

        for (i, btn) in buttons.enumerated() {
            if btn.frame.insetBy(dx: -2, dy: -60).contains(point) {
                select(index: i)
                return
            }
        }
        clearSelection()
    }

    func confirmSelection() {
        if let idx = selectedIndex {
            delegate?.popupDidSelect(alternates[idx])
        } else {
            delegate?.popupDidCancel()
        }
    }

    // MARK: - Private helpers

    private func select(index: Int) {
        guard index != selectedIndex else { return }
        clearSelection()
        selectedIndex = index
        buttons[index].isSelected = true
        buttons[index].backgroundColor = UIColor(named: "KeyHighlight") ?? UIColor.systemBlue
    }

    private func clearSelection() {
        if let prev = selectedIndex {
            buttons[prev].isSelected = false
            buttons[prev].backgroundColor = .clear
        }
        selectedIndex = nil
    }

    // Mirror of KeyButton.visibleText — tatweel base for standalone combining marks.
    // Invisible control characters get a short descriptive label instead.
    private func visibleTitle(_ text: String) -> String {
        switch text {
        case "\u{00A0}": return "NBSP"
        case "\u{200C}": return "ZWNJ"
        default: break
        }
        guard !text.isEmpty,
              text.unicodeScalars.allSatisfy({ $0.properties.generalCategory == .nonspacingMark })
        else { return text }
        return "ـ" + text
    }

    // Returns true when the title is a descriptive label rather than a glyph,
    // so we can use a smaller system font instead of the Arabic typeface.
    private func isLabel(_ title: String) -> Bool {
        title.unicodeScalars.allSatisfy({ $0.value < 128 })  // ASCII = label
    }
}
