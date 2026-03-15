import SwiftUI

struct NodeView: View {
    let node: ThoughtNode
    let isSelected: Bool
    let isSearchHighlighted: Bool
    let onSelect: () -> Void
    let onMove: (CGSize) -> Void
    let onEditText: (String) -> Void

    @State private var isEditing = false
    @State private var editText: String = ""
    @State private var dragOffset: CGSize = .zero
    @State private var appeared = false

    private var seed: Int { Int(node.id ?? 0) }
    private var isEmpty: Bool { node.text.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Stroke opacity — empty nodes look lighter, like drawn lightly pending content
    private var strokeOpacity: Double { isEmpty ? 0.55 : 0.92 }

    var body: some View {
        let nodeRect = CGRect(x: 0, y: 0, width: node.width, height: node.height)

        ZStack {
            // Hand-drawn selection circle (behind everything)
            if isSelected {
                SketchRenderer.selectionCircle(around: nodeRect, seed: seed)
                    .stroke(Color.gzBrand.opacity(0.6), lineWidth: 1.2)
            }

            // Fill — warm near-white, slightly warmer than canvas
            SketchRenderer.sketchyRectFill(in: nodeRect, seed: seed)
                .fill(isSearchHighlighted
                    ? Color.gzSearchHighlight
                    : Color(red: 0.992, green: 0.976, blue: 0.957) // #fdf9f4
                )

            // Double-stroke pencil outline with variable opacity
            SketchRenderer.sketchyRect(in: nodeRect, seed: seed)
                .stroke(
                    Color.gzNodeStroke.opacity(isSelected ? 1.0 : strokeOpacity),
                    lineWidth: isSelected ? 1.6 : 1.0
                )

            // Content layer
            if isEditing {
                TextField("", text: $editText)
                    .onSubmit {
                        onEditText(editText)
                        isEditing = false
                    }
                    .textFieldStyle(.plain)
                    .font(GZFont.hand())
                    .foregroundColor(.gzText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(width: node.width, height: node.height)
            } else if isEmpty {
                // Placeholder — faint pencil mark
                SketchRenderer.placeholderLine(in: nodeRect, seed: seed)
                    .stroke(Color.gzStroke.opacity(0.2), lineWidth: 1.0)
            } else {
                Text(node.text)
                    .font(GZFont.hand())
                    .foregroundColor(.gzText)
                    .lineLimit(4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(width: node.width, height: node.height, alignment: .topLeading)
            }
        }
        .frame(width: node.width + 20, height: node.height + 20) // extra space for selection circle
        .position(x: node.x + node.width / 2 + dragOffset.width,
                  y: node.y + node.height / 2 + dragOffset.height)
        // Appear animation
        .scaleEffect(appeared ? 1.0 : 0.3)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            if Date().timeIntervalSince(node.createdAt) < 1.0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                    appeared = true
                }
            } else {
                appeared = true
            }
        }
        // Gestures
        .onTapGesture(count: 2) {
            editText = node.text
            isEditing = true
        }
        .onTapGesture(count: 1) {
            onSelect()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    onMove(value.translation)
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
        )
    }
}
