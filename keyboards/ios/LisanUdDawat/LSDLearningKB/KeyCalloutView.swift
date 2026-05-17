import UIKit

// Bubble that appears above a key the moment it is pressed — just like the
// native iOS keyboard callout. Drawn with a rounded rect + downward pointer.
// Positioned by KeyboardView so it can escape the key's clipping bounds.

final class KeyCalloutView: UIView {

    private let label = UILabel()
    private static let pointerH: CGFloat = 8
    private static let cornerR:  CGFloat = 8

    init(character: String, keyFrame: CGRect, in container: UIView) {
        let font   = UIFont(name: "FatemiMaqala", size: 28) ?? UIFont.systemFont(ofSize: 28)
        let charW  = max(44, character.size(withAttributes: [.font: font]).width + 20)
        let bubbleH: CGFloat = keyFrame.height  // 1:1 fits within the calloutOverflow zone
        let pointerH = KeyCalloutView.pointerH

        // Centre over the key, clamp to container edges
        var x = keyFrame.midX - charW / 2
        x = max(4, min(container.bounds.width - charW - 4, x))
        let y = keyFrame.minY - bubbleH - pointerH + 4

        super.init(frame: CGRect(x: x, y: y, width: charW, height: bubbleH + pointerH))
        backgroundColor = .clear
        isUserInteractionEnabled = false

        label.text = character
        label.textColor = .white
        label.font = font
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 0, width: charW, height: bubbleH)
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let r   = KeyCalloutView.cornerR
        let pH  = KeyCalloutView.pointerH
        let bH  = rect.height - pH
        let w   = rect.width
        let mid = w / 2

        let path = UIBezierPath()
        // Top-left
        path.move(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: w - r, y: 0))
        path.addArc(withCenter: CGPoint(x: w - r, y: r), radius: r,
                    startAngle: -.pi / 2, endAngle: 0, clockwise: true)
        // Right side
        path.addLine(to: CGPoint(x: w, y: bH - r))
        path.addArc(withCenter: CGPoint(x: w - r, y: bH - r), radius: r,
                    startAngle: 0, endAngle: .pi / 2, clockwise: true)
        // Pointer
        path.addLine(to: CGPoint(x: mid + pH, y: bH))
        path.addLine(to: CGPoint(x: mid,       y: bH + pH))
        path.addLine(to: CGPoint(x: mid - pH,  y: bH))
        // Bottom-left
        path.addLine(to: CGPoint(x: r, y: bH))
        path.addArc(withCenter: CGPoint(x: r, y: bH - r), radius: r,
                    startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addArc(withCenter: CGPoint(x: r, y: r), radius: r,
                    startAngle: .pi, endAngle: -.pi / 2, clockwise: true)
        path.close()

        // Resolve against current trait collection — CGContext doesn't do this automatically
        KeyboardColors.calloutBubble.resolvedColor(with: traitCollection).setFill()
        ctx.addPath(path.cgPath)
        ctx.fillPath()
    }
}
