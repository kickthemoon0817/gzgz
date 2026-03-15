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

    var body: some View {
        ZStack {
            // Fill layer
            SketchRenderer.sketchyRectFill(
                in: CGRect(x: 0, y: 0, width: node.width, height: node.height),
                seed: seed
            )
            .fill(isSearchHighlighted ? Color.gzSearchHighlight : Color.gzNodeFill)

            // Double-stroke outline
            SketchRenderer.sketchyRect(
                in: CGRect(x: 0, y: 0, width: node.width, height: node.height),
                seed: seed
            )
            .stroke(
                isSelected ? Color.gzSelectionStroke : Color.gzNodeStroke,
                lineWidth: isSelected ? 2.0 : 1.0
            )

            // Text content
            if isEditing {
                TextField("", text: $editText)
                    .onSubmit {
                        onEditText(editText)
                        isEditing = false
                    }
                    .textFieldStyle(.plain)
                    .font(GZFont.hand())
                    .foregroundColor(.gzText)
                    .padding(14)
                    .frame(width: node.width, height: node.height)
            } else {
                Text(node.text.isEmpty ? "" : node.text)
                    .font(GZFont.hand())
                    .foregroundColor(.gzText)
                    .lineLimit(3)
                    .padding(14)
                    .frame(width: node.width, height: node.height, alignment: .topLeading)
            }
        }
        .frame(width: node.width, height: node.height)
        .position(x: node.x + node.width / 2 + dragOffset.width,
                  y: node.y + node.height / 2 + dragOffset.height)
        .scaleEffect(appeared ? 1.0 : 0.0)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            if Date().timeIntervalSince(node.createdAt) < 1.0 {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    appeared = true
                }
            } else {
                appeared = true
            }
        }
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
