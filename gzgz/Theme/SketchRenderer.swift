import SwiftUI

/// Roughjs-inspired sketch renderer that creates hand-drawn looking shapes.
/// Key technique: double-stroke lines with slight offset, curve-based wobble,
/// and deterministic seeded randomness for consistent rendering.
enum SketchRenderer {

    // MARK: - Seeded Random

    /// Simple seeded PRNG for deterministic wobble
    struct SeededRandom {
        private var state: UInt64

        init(seed: Int) {
            state = UInt64(bitPattern: Int64(seed &* 2654435761 &+ 1013904223))
            if state == 0 { state = 1 }
        }

        mutating func next() -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let shifted = (state >> 33) ^ state
            return Double(shifted % 10000) / 10000.0
        }

        /// Returns value in range [-magnitude, magnitude]
        mutating func wobble(_ magnitude: Double = 1.0) -> Double {
            return (next() - 0.5) * 2.0 * magnitude
        }
    }

    // MARK: - Sketchbook Paper Background

    /// Lightweight paper background — warm tint with subtle noise via overlay
    static func paperBackground() -> some View {
        ZStack {
            // Warm paper base
            Color(red: 0.98, green: 0.973, blue: 0.96)

            // Subtle grain noise via thin repeating pattern
            Canvas { context, size in
                // Sparse grain — only ~200 specks total, not per-pixel
                var rng = SeededRandom(seed: 42)
                for _ in 0..<200 {
                    let x = rng.next() * size.width
                    let y = rng.next() * size.height
                    let r = 0.5 + rng.next() * 1.0
                    let opacity = 0.025 + rng.next() * 0.03
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                        with: .color(.brown.opacity(opacity))
                    )
                }
            }
            .allowsHitTesting(false)
        }
        .drawingGroup()  // moved to ZStack level
    }

    // MARK: - Selection Circle (hand-drawn loop around a rect)

    /// Hand-drawn elliptical loop around a node — like someone circled it with a pen
    static func selectionCircle(around rect: CGRect, seed: Int) -> Path {
        var path = Path()
        var rng = SeededRandom(seed: seed &+ 333)

        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width / 2 + 14  // generous padding outside node
        let ry = rect.height / 2 + 14
        let segments = 20

        // Draw an imperfect ellipse with visible wobble, slight overshoot (doesn't close perfectly)
        for i in 0...segments {
            let angle = Double(i) / Double(segments) * 2.0 * .pi * 1.08
            let wobbleR = rng.wobble(6.0)
            let x = cx + (rx + wobbleR) * cos(angle)
            let y = cy + (ry + wobbleR) * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                let ctrlAngle = (Double(i) - 0.5) / Double(segments) * 2.0 * .pi * 1.08
                let ctrlWobble = rng.wobble(5.0)
                let ctrlX = cx + (rx + ctrlWobble) * cos(ctrlAngle)
                let ctrlY = cy + (ry + ctrlWobble) * sin(ctrlAngle)
                path.addQuadCurve(
                    to: CGPoint(x: x, y: y),
                    control: CGPoint(x: ctrlX, y: ctrlY)
                )
            }
        }

        return path
    }

    // MARK: - Placeholder Line (faint pencil mark for empty nodes)

    /// A short wobbly horizontal line, like a pencil mark on blank paper
    static func placeholderLine(in rect: CGRect, seed: Int) -> Path {
        var path = Path()
        var rng = SeededRandom(seed: seed &+ 111)

        let y = rect.minY + 20
        let startX = rect.minX + 14
        let endX = startX + rect.width * 0.5

        path.move(to: CGPoint(x: startX, y: y + rng.wobble(0.5)))
        let segments = 6
        for i in 1...segments {
            let t = Double(i) / Double(segments)
            let x = startX + (endX - startX) * t
            path.addLine(to: CGPoint(x: x, y: y + rng.wobble(0.8)))
        }

        return path
    }

    // MARK: - Sketchy Rectangle (Double-Stroke)

    /// Creates a hand-drawn rectangle using double-stroke technique like roughjs.
    /// Two slightly offset strokes give the characteristic hand-drawn look.
    static func sketchyRect(
        in rect: CGRect,
        seed: Int,
        wobbleMagnitude: Double = 2.0
    ) -> Path {
        var path = Path()
        var rng = SeededRandom(seed: seed)

        // Draw rectangle twice with slight variation (roughjs double-stroke)
        for pass in 0..<2 {
            let offset = pass == 0 ? 0.0 : 1.2
            let corners = [
                CGPoint(x: rect.minX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.maxY)
            ]

            for edge in 0..<4 {
                let from = corners[edge]
                let to = corners[(edge + 1) % 4]
                let wobbledFrom = CGPoint(
                    x: from.x + rng.wobble(wobbleMagnitude) + offset,
                    y: from.y + rng.wobble(wobbleMagnitude) + offset
                )
                let wobbledTo = CGPoint(
                    x: to.x + rng.wobble(wobbleMagnitude) + offset,
                    y: to.y + rng.wobble(wobbleMagnitude) + offset
                )

                if edge == 0 && pass == 0 {
                    path.move(to: wobbledFrom)
                } else if edge == 0 {
                    path.move(to: wobbledFrom)
                }

                // Use quadratic curve with a slight bulge for natural hand-drawn feel
                let midX = (wobbledFrom.x + wobbledTo.x) / 2 + rng.wobble(wobbleMagnitude * 0.6)
                let midY = (wobbledFrom.y + wobbledTo.y) / 2 + rng.wobble(wobbleMagnitude * 0.6)
                let control = CGPoint(x: midX, y: midY)
                path.addQuadCurve(to: wobbledTo, control: control)
            }
        }

        return path
    }

    /// Single-pass fill shape (no double stroke, used for the fill layer)
    static func sketchyRectFill(
        in rect: CGRect,
        seed: Int,
        wobbleMagnitude: Double = 0.5
    ) -> Path {
        var path = Path()
        var rng = SeededRandom(seed: seed &+ 999)

        let corners = [
            CGPoint(x: rect.minX + rng.wobble(wobbleMagnitude),
                    y: rect.minY + rng.wobble(wobbleMagnitude)),
            CGPoint(x: rect.maxX + rng.wobble(wobbleMagnitude),
                    y: rect.minY + rng.wobble(wobbleMagnitude)),
            CGPoint(x: rect.maxX + rng.wobble(wobbleMagnitude),
                    y: rect.maxY + rng.wobble(wobbleMagnitude)),
            CGPoint(x: rect.minX + rng.wobble(wobbleMagnitude),
                    y: rect.maxY + rng.wobble(wobbleMagnitude))
        ]

        path.move(to: corners[0])
        for i in 1..<corners.count {
            path.addLine(to: corners[i])
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Sketchy Line (Double-Stroke with Curves)

    /// Creates a hand-drawn line using double-stroke with quadratic curves
    static func sketchyLine(
        from start: CGPoint,
        to end: CGPoint,
        seed: Int,
        wobbleMagnitude: Double = 1.5
    ) -> Path {
        var path = Path()
        var rng = SeededRandom(seed: seed)

        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return path }

        // Draw the line twice with slight offset (double-stroke)
        for pass in 0..<2 {
            let passOffset = pass == 0 ? 0.0 : 0.4
            let segments = min(8, max(2, Int(length / 50)))

            let startWobbled = CGPoint(
                x: start.x + rng.wobble(wobbleMagnitude * 0.3) + passOffset,
                y: start.y + rng.wobble(wobbleMagnitude * 0.3) + passOffset
            )
            path.move(to: startWobbled)

            let nx = -dy / length
            let ny = dx / length

            var i = 1
            while i <= segments {
                let t = Double(i) / Double(segments)
                let baseX = start.x + dx * t
                let baseY = start.y + dy * t
                let w = rng.wobble(wobbleMagnitude) + passOffset
                let point = CGPoint(x: baseX + nx * w, y: baseY + ny * w)

                if i >= segments {
                    path.addLine(to: CGPoint(
                        x: end.x + rng.wobble(wobbleMagnitude * 0.3),
                        y: end.y + rng.wobble(wobbleMagnitude * 0.3)
                    ))
                    i += 1
                } else {
                    let controlW = rng.wobble(wobbleMagnitude * 0.5)
                    let nextT = Double(min(i + 1, segments)) / Double(segments)
                    let nextX = start.x + dx * nextT + nx * controlW
                    let nextY = start.y + dy * nextT + ny * controlW
                    path.addQuadCurve(to: CGPoint(x: nextX, y: nextY), control: point)
                    i += 2
                }
            }
        }

        return path
    }

    // MARK: - Arrowhead (Hand-Drawn)

    /// Hand-drawn arrowhead with slight wobble
    static func arrowhead(at point: CGPoint, angle: Double, size: CGFloat = 14, seed: Int = 0) -> Path {
        var path = Path()
        var rng = SeededRandom(seed: seed &+ 777)

        let spread: Double = .pi / 7
        let left = CGPoint(
            x: point.x - size * cos(angle - spread) + rng.wobble(1.0),
            y: point.y - size * sin(angle - spread) + rng.wobble(1.0)
        )
        let right = CGPoint(
            x: point.x - size * cos(angle + spread) + rng.wobble(1.0),
            y: point.y - size * sin(angle + spread) + rng.wobble(1.0)
        )
        let tip = CGPoint(
            x: point.x + rng.wobble(0.5),
            y: point.y + rng.wobble(0.5)
        )

        // Draw each arm of the arrowhead as a short sketchy stroke
        path.move(to: left)
        path.addLine(to: tip)
        path.move(to: right)
        path.addLine(to: tip)

        return path
    }

    // MARK: - Cross-Hatch Fill (Excalidraw-style)

    /// Optional cross-hatch fill for shapes
    static func crossHatchFill(
        in rect: CGRect,
        seed: Int,
        spacing: CGFloat = 8,
        angle: Double = -0.7
    ) -> Path {
        var path = Path()
        var rng = SeededRandom(seed: seed &+ 555)

        let cos_a = cos(angle)
        let sin_a = sin(angle)
        let diagonal = sqrt(rect.width * rect.width + rect.height * rect.height)
        let lines = Int(diagonal / spacing)

        for i in 0..<lines {
            let offset = CGFloat(i) * spacing - diagonal / 2
            let x1 = rect.midX + offset * cos_a - diagonal / 2 * sin_a
            let y1 = rect.midY + offset * sin_a + diagonal / 2 * cos_a
            let x2 = rect.midX + offset * cos_a + diagonal / 2 * sin_a
            let y2 = rect.midY + offset * sin_a - diagonal / 2 * cos_a

            let start = CGPoint(x: x1 + rng.wobble(0.5), y: y1 + rng.wobble(0.5))
            let end = CGPoint(x: x2 + rng.wobble(0.5), y: y2 + rng.wobble(0.5))

            // Clip to rect bounds
            if let clipped = clipLine(from: start, to: end, in: rect) {
                path.move(to: clipped.0)
                path.addLine(to: clipped.1)
            }
        }

        return path
    }

    private static func clipLine(from: CGPoint, to: CGPoint, in rect: CGRect) -> (CGPoint, CGPoint)? {
        var t0: CGFloat = 0, t1: CGFloat = 1
        let dx = to.x - from.x
        let dy = to.y - from.y

        let edges: [(CGFloat, CGFloat)] = [
            (-dx, from.x - rect.minX),
            (dx, rect.maxX - from.x),
            (-dy, from.y - rect.minY),
            (dy, rect.maxY - from.y)
        ]

        for (p, q) in edges {
            if p == 0 {
                if q < 0 { return nil }
            } else {
                let r = q / p
                if p < 0 { t0 = max(t0, r) }
                else { t1 = min(t1, r) }
            }
        }

        if t0 > t1 { return nil }

        return (
            CGPoint(x: from.x + t0 * dx, y: from.y + t0 * dy),
            CGPoint(x: from.x + t1 * dx, y: from.y + t1 * dy)
        )
    }
}
