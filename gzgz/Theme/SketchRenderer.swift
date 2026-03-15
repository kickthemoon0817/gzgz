import SwiftUI

enum SketchRenderer {
    /// Seed-based random for deterministic wobble per shape
    static func wobble(seed: Int, index: Int, magnitude: Double = 2.0) -> Double {
        let hash = abs(seed &* 31 &+ index)
        let normalized = Double(hash % 1000) / 1000.0
        return (normalized - 0.5) * magnitude * 2
    }

    /// Create a sketchy rounded rectangle path with wobbly edges
    static func sketchyRect(
        in rect: CGRect,
        seed: Int,
        cornerRadius: CGFloat = 8,
        wobbleMagnitude: Double = 1.5
    ) -> Path {
        var path = Path()
        let segments = 20
        let w = rect.width
        let h = rect.height

        // Top edge
        for i in 0...segments {
            let t = Double(i) / Double(segments)
            let x = rect.minX + w * t
            let y = rect.minY + wobble(seed: seed, index: i, magnitude: wobbleMagnitude)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        // Right edge
        for i in 0...segments {
            let t = Double(i) / Double(segments)
            let x = rect.maxX + wobble(seed: seed, index: segments + i, magnitude: wobbleMagnitude)
            let y = rect.minY + h * t
            path.addLine(to: CGPoint(x: x, y: y))
        }
        // Bottom edge
        for i in 0...segments {
            let t = 1.0 - Double(i) / Double(segments)
            let x = rect.minX + w * t
            let y = rect.maxY + wobble(seed: seed, index: 2 * segments + i, magnitude: wobbleMagnitude)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        // Left edge
        for i in 0...segments {
            let t = 1.0 - Double(i) / Double(segments)
            let x = rect.minX + wobble(seed: seed, index: 3 * segments + i, magnitude: wobbleMagnitude)
            let y = rect.minY + h * t
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.closeSubpath()
        return path
    }

    /// Create a sketchy line path between two points
    static func sketchyLine(
        from start: CGPoint,
        to end: CGPoint,
        seed: Int,
        wobbleMagnitude: Double = 2.0
    ) -> Path {
        var path = Path()
        let segments = 16
        path.move(to: start)

        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return path }
        let nx = -dy / length
        let ny = dx / length

        for i in 1...segments {
            let t = Double(i) / Double(segments)
            let baseX = start.x + dx * t
            let baseY = start.y + dy * t
            let w = wobble(seed: seed, index: i, magnitude: wobbleMagnitude)
            let x = baseX + nx * w
            let y = baseY + ny * w
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }

    /// Arrowhead at end of a line
    static func arrowhead(at point: CGPoint, angle: Double, size: CGFloat = 12) -> Path {
        var path = Path()
        let left = CGPoint(
            x: point.x - size * cos(angle - .pi / 6),
            y: point.y - size * sin(angle - .pi / 6)
        )
        let right = CGPoint(
            x: point.x - size * cos(angle + .pi / 6),
            y: point.y - size * sin(angle + .pi / 6)
        )
        path.move(to: left)
        path.addLine(to: point)
        path.addLine(to: right)
        return path
    }
}
