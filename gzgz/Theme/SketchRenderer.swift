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

    /// Procedural sketchbook paper texture — subtle grain + faint fiber lines
    static func paperTexture(in size: CGSize, seed: Int = 42) -> some View {
        Canvas { context, canvasSize in
            var rng = SeededRandom(seed: seed)

            // Base warm paper tint
            context.fill(
                Path(CGRect(origin: .zero, size: canvasSize)),
                with: .color(Color(red: 0.98, green: 0.973, blue: 0.96))
            )

            // Paper grain — tiny scattered specks
            let grainCount = Int(canvasSize.width * canvasSize.height / 120)
            for _ in 0..<grainCount {
                let x = rng.next() * canvasSize.width
                let y = rng.next() * canvasSize.height
                let radius = 0.3 + rng.next() * 0.5
                let opacity = 0.02 + rng.next() * 0.04
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(opacity)))
            }

            // Faint horizontal fiber lines — like real paper
            let fiberCount = Int(canvasSize.height / 3)
            for i in 0..<fiberCount {
                let y = rng.next() * canvasSize.height
                let startX = rng.next() * canvasSize.width * 0.3
                let length = 20 + rng.next() * 60
                let opacity = 0.015 + rng.next() * 0.02

                var fiberPath = Path()
                fiberPath.move(to: CGPoint(x: startX, y: y))
                fiberPath.addLine(to: CGPoint(x: startX + length, y: y + rng.wobble(0.5)))
                context.stroke(fiberPath, with: .color(.brown.opacity(opacity)), lineWidth: 0.3)
            }

            // Very subtle edge vignette — darker edges like real paper
            let vignetteRect = CGRect(origin: .zero, size: canvasSize).insetBy(dx: -50, dy: -50)
            let gradient = Gradient(colors: [
                .clear,
                .black.opacity(0.02)
            ])
            context.fill(
                Path(ellipseIn: vignetteRect),
                with: .radialGradient(gradient,
                    center: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
                    startRadius: min(canvasSize.width, canvasSize.height) * 0.3,
                    endRadius: max(canvasSize.width, canvasSize.height) * 0.7
                )
            )
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Sketchy Rectangle (Double-Stroke)

    /// Creates a hand-drawn rectangle using double-stroke technique like roughjs.
    /// Two slightly offset strokes give the characteristic hand-drawn look.
    static func sketchyRect(
        in rect: CGRect,
        seed: Int,
        wobbleMagnitude: Double = 0.8
    ) -> Path {
        var path = Path()
        var rng = SeededRandom(seed: seed)

        // Draw rectangle twice with slight variation (roughjs double-stroke)
        for pass in 0..<2 {
            let offset = pass == 0 ? 0.0 : 0.5
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
            let segments = max(2, Int(length / 30))

            let startWobbled = CGPoint(
                x: start.x + rng.wobble(wobbleMagnitude * 0.3) + passOffset,
                y: start.y + rng.wobble(wobbleMagnitude * 0.3) + passOffset
            )
            path.move(to: startWobbled)

            let nx = -dy / length
            let ny = dx / length

            for i in 1...segments {
                let t = Double(i) / Double(segments)
                let baseX = start.x + dx * t
                let baseY = start.y + dy * t
                let w = rng.wobble(wobbleMagnitude) + passOffset

                let point = CGPoint(x: baseX + nx * w, y: baseY + ny * w)

                if i == segments {
                    // End at the actual endpoint with slight wobble
                    path.addLine(to: CGPoint(
                        x: end.x + rng.wobble(wobbleMagnitude * 0.3),
                        y: end.y + rng.wobble(wobbleMagnitude * 0.3)
                    ))
                } else {
                    let controlW = rng.wobble(wobbleMagnitude * 0.5)
                    let nextT = Double(i + 1) / Double(segments)
                    let nextX = start.x + dx * nextT + nx * controlW
                    let nextY = start.y + dy * nextT + ny * controlW
                    path.addQuadCurve(to: CGPoint(x: nextX, y: nextY), control: point)
                    // Skip next iteration since we drew two segments
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
