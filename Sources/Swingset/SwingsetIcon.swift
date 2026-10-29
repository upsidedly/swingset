import AppKit

enum SwingsetIcon {
    static func drawMark(in rect: CGRect, color: NSColor) {
        NSGraphicsContext.saveGraphicsState(); defer { NSGraphicsContext.restoreGraphicsState() }
        let transform = NSAffineTransform(); transform.translateX(by: rect.minX, yBy: rect.minY); transform.scaleX(by: rect.width / 100, yBy: rect.height / 100); transform.concat()
        color.setStroke(); color.setFill()
        let frame = NSBezierPath(); frame.lineWidth = 6.3; frame.lineCapStyle = .round; frame.lineJoinStyle = .round
        frame.move(to: CGPoint(x: 17, y: 19)); frame.line(to: CGPoint(x: 17, y: 79)); frame.line(to: CGPoint(x: 83, y: 79)); frame.line(to: CGPoint(x: 83, y: 19)); frame.stroke()
        let strings = NSBezierPath(); strings.lineWidth = 3.5
        for x in [34.0, 50.0] { strings.move(to: CGPoint(x: x, y: 76)); strings.line(to: CGPoint(x: x, y: 43)) }
        strings.move(to: CGPoint(x: 66, y: 76)); strings.line(to: CGPoint(x: 80, y: 47)); strings.stroke()
        for point in [CGPoint(x: 34,y: 36), CGPoint(x: 50,y: 36), CGPoint(x: 83,y: 40)] { NSBezierPath(ovalIn: CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16)).fill() }
    }
}
