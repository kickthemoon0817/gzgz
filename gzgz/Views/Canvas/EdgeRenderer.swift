import SwiftUI

struct EdgeRenderer: View {
    let edge: Edge
    let sourceNode: ThoughtNode
    let targetNode: ThoughtNode
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var drawProgress: CGFloat = 0

    private var seed: Int { Int(edge.id ?? 0) &+ 1000 }

    private var sourceCenter: CGPoint {
        CGPoint(x: sourceNode.x + sourceNode.width / 2,
                y: sourceNode.y + sourceNode.height / 2)
    }

    private var targetCenter: CGPoint {
        CGPoint(x: targetNode.x + targetNode.width / 2,
                y: targetNode.y + targetNode.height / 2)
    }

    private var edgePoints: (start: CGPoint, end: CGPoint) {
        guard sourceNode.width > 0, sourceNode.height > 0,
              targetNode.width > 0, targetNode.height > 0 else {
            return (sourceCenter, targetCenter)
        }
        let start = clipToRect(
            from: sourceCenter, to: targetCenter,
            rect: CGRect(x: sourceNode.x, y: sourceNode.y,
                         width: sourceNode.width, height: sourceNode.height)
        )
        let end = clipToRect(
            from: targetCenter, to: sourceCenter,
            rect: CGRect(x: targetNode.x, y: targetNode.y,
                         width: targetNode.width, height: targetNode.height)
        )
        return (start, end)
    }

    var body: some View {
        let points = edgePoints
        let angle = atan2(points.end.y - points.start.y, points.end.x - points.start.x)
        let linePath = SketchRenderer.sketchyLine(from: points.start, to: points.end, seed: seed)

        ZStack {
            // Hand-drawn line (double-stroke)
            linePath
                .trim(from: 0, to: drawProgress)
                .stroke(
                    isSelected ? Color.gzSelectionStroke : Color.gzEdgeStroke,
                    lineWidth: isSelected ? 2.0 : 1.0
                )

            // Arrowhead
            if drawProgress >= 1.0 {
                SketchRenderer.arrowhead(at: points.end, angle: angle, seed: seed)
                    .stroke(
                        isSelected ? Color.gzSelectionStroke : Color.gzEdgeStroke,
                        lineWidth: isSelected ? 2.0 : 1.0
                    )
                    .transition(.opacity)
            }

            // Label
            if let label = edge.label, !label.isEmpty {
                let mid = CGPoint(
                    x: (points.start.x + points.end.x) / 2,
                    y: (points.start.y + points.end.y) / 2 - 14
                )
                Text(label)
                    .font(GZFont.label())
                    .foregroundColor(.gzTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gzCanvasBackground.opacity(0.85))
                    .position(mid)
            }
        }
        .contentShape(
            linePath
                .stroke(lineWidth: 12)
        )
        .onTapGesture { onSelect() }
        .onAppear {
            drawProgress = 0
            withAnimation(.easeOut(duration: 0.4)) {
                drawProgress = 1.0
            }
        }
    }

    private func clipToRect(from: CGPoint, to: CGPoint, rect: CGRect) -> CGPoint {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let cx = from.x
        let cy = from.y

        var tMin: CGFloat = 1.0

        if dx != 0 {
            let tLeft = (rect.minX - cx) / dx
            let tRight = (rect.maxX - cx) / dx
            for t in [tLeft, tRight] where t > 0 && t < tMin {
                let y = cy + t * dy
                if y >= rect.minY && y <= rect.maxY { tMin = t }
            }
        }
        if dy != 0 {
            let tTop = (rect.minY - cy) / dy
            let tBottom = (rect.maxY - cy) / dy
            for t in [tTop, tBottom] where t > 0 && t < tMin {
                let x = cx + t * dx
                if x >= rect.minX && x <= rect.maxX { tMin = t }
            }
        }

        return CGPoint(x: cx + tMin * dx, y: cy + tMin * dy)
    }
}
