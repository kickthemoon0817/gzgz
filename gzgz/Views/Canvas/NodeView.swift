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

    private var seed: Int { Int(node.id ?? 0) }

    var body: some View {
        ZStack {
            // Sketchy rectangle background
            SketchRenderer.sketchyRect(
                in: CGRect(x: 0, y: 0, width: node.width, height: node.height),
                seed: seed
            )
            .fill(isSearchHighlighted ? Color.gzSearchHighlight : Color.gzNodeFill)

            SketchRenderer.sketchyRect(
                in: CGRect(x: 0, y: 0, width: node.width, height: node.height),
                seed: seed
            )
            .stroke(
                isSelected ? Color.gzPrimary : Color.gzNodeStroke,
                lineWidth: isSelected ? 2.5 : 1.5
            )

            // Text content
            if isEditing {
                TextField("", text: $editText, onCommit: {
                    onEditText(editText)
                    isEditing = false
                })
                .textFieldStyle(.plain)
                .font(GZFont.node())
                .foregroundColor(.gzText)
                .padding(12)
                .frame(width: node.width, height: node.height)
            } else {
                Text(node.text.isEmpty ? "..." : node.text)
                    .font(GZFont.node())
                    .foregroundColor(node.text.isEmpty ? .gzTextSecondary : .gzText)
                    .lineLimit(3)
                    .padding(12)
                    .frame(width: node.width, height: node.height, alignment: .topLeading)
            }
        }
        .frame(width: node.width, height: node.height)
        .position(x: node.x + node.width / 2 + dragOffset.width,
                  y: node.y + node.height / 2 + dragOffset.height)
        .onTapGesture(count: 2) {
            editText = node.text
            isEditing = true
        }
        .onTapGesture(count: 1) {
            onSelect()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    onMove(value.translation)
                    dragOffset = .zero
                }
        )
        .shadow(color: Color.gzPrimary.opacity(isSelected ? 0.2 : 0), radius: 8)
    }
}
