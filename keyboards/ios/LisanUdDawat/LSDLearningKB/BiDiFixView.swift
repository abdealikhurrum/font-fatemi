import UIKit

// Animated button shown in the predictive bar when mixed-script text is detected.
// Displays a mini before→after loop: the LTR fragment slides from the wrong
// side to the correct side and back, showing the user what the fix will do.

final class BiDiFixView: UIView {

    var onTap: (() -> Void)?

    private var rtlString = "ع"
    private var ltrString = "123"

    // 0 = broken state, 1 = fixed state
    private var animPhase: CGFloat = 0
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private let cycleDuration: CFTimeInterval = 3.2

    private let rtlLabel = UILabel()
    private let ltrLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        rtlLabel.font = UIFont(name: "FatemiMaqala-Regular", size: 12) ?? .systemFont(ofSize: 12)
        ltrLabel.font = .systemFont(ofSize: 11)
        rtlLabel.textAlignment = .center
        ltrLabel.textAlignment = .center
        addSubview(rtlLabel)
        addSubview(ltrLabel)

        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    func setIssue(_ issue: BiDiAnalyzer.Issue?) {
        if let issue {
            rtlString = issue.previewRtl
            ltrString = issue.previewLtr
            if displayLink == nil { startAnimating() }
        } else {
            stopAnimating()
        }
    }

    // MARK: - Animation

    private func startAnimating() {
        startTime = CACurrentMediaTime()
        let dl = CADisplayLink(target: self, selector: #selector(tick))
        dl.add(to: .main, forMode: .common)
        displayLink = dl
    }

    private func stopAnimating() {
        displayLink?.invalidate()
        displayLink = nil
        animPhase = 0
        setNeedsLayout()
    }

    @objc private func tick() {
        let elapsed = CACurrentMediaTime() - startTime
        let r = Float(elapsed.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration)
        let raw: Float
        switch r {
        case ..<0.25: raw = r / 0.25
        case ..<0.65: raw = 1.0
        case ..<0.80: raw = 1.0 - (r - 0.65) / 0.15
        default:      raw = 0.0
        }
        animPhase = CGFloat(smoothStep(raw))
        updateColors()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height
        let rtlW = rtlLabel.sizeThatFits(bounds.size).width + 2
        let ltrW = ltrLabel.sizeThatFits(bounds.size).width + 2
        let gap:  CGFloat = 3
        let total = rtlW + ltrW + gap
        let originX = (bounds.width - total) / 2

        // Broken state: [ltr][gap][rtl]  →  Fixed: [rtl][gap][ltr]
        let t = animPhase
        let ltrX = originX + (rtlW + gap) * t
        let rtlX = originX + (ltrW + gap) * (1 - t)

        ltrLabel.frame = CGRect(x: ltrX, y: 0, width: ltrW, height: h)
        rtlLabel.frame = CGRect(x: rtlX, y: 0, width: rtlW, height: h)

        rtlLabel.text = rtlString
        ltrLabel.text = ltrString
    }

    private func updateColors() {
        let accent = UIColor(red: 0, green: 0.478, blue: 1, alpha: 1)
        let base   = UIColor.label
        let dim    = UIColor.tertiaryLabel
        rtlLabel.textColor = interpolate(from: base,   to: accent, t: animPhase)
        ltrLabel.textColor = interpolate(from: dim,    to: accent, t: animPhase)
    }

    @objc private func tapped() { onTap?() }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { stopAnimating() }
    }

    // MARK: - Helpers

    private func smoothStep(_ x: Float) -> Float {
        let t = max(0, min(1, x))
        return t * t * (3 - 2 * t)
    }

    private func interpolate(from a: UIColor, to b: UIColor, t: CGFloat) -> UIColor {
        var r1: CGFloat = 0; var g1: CGFloat = 0; var b1: CGFloat = 0; var a1: CGFloat = 0
        var r2: CGFloat = 0; var g2: CGFloat = 0; var b2: CGFloat = 0; var a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red:   r1 + (r2 - r1) * t,
                       green: g1 + (g2 - g1) * t,
                       blue:  b1 + (b2 - b1) * t,
                       alpha: a1 + (a2 - a1) * t)
    }
}
