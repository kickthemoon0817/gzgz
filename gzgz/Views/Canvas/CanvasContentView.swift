import SwiftUI

struct CanvasContentView: View {
    @Bindable var vm: CanvasViewModel
    var highlightedNodeIds: Set<Int64> = []

    @State private var zoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero
    @State private var lastPan: CGSize = .zero
    @State private var lastZoom: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sketchbook paper background
                SketchRenderer.paperBackground()
                    .allowsHitTesting(false)

                // Background tap targets
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { location in
                        let canvasPoint = screenToCanvas(location, in: geometry.size)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            try? vm.createNode(at: canvasPoint)
                        }
                    }
                    .simultaneousGesture(TapGesture(count: 1).onEnded { vm.clearSelection() })
                    // Two-finger drag to pan (no modifier needed)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                pan = CGSize(
                                    width: lastPan.width + value.translation.width,
                                    height: lastPan.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastPan = pan
                            }
                    )
                    // Pinch to zoom
                    .simultaneousGesture(
                        MagnifyGesture()
                            .onChanged { value in
                                zoom = max(0.1, min(5.0, lastZoom * value.magnification))
                            }
                            .onEnded { _ in
                                lastZoom = zoom
                            }
                    )

                // Canvas content with transform
                ZStack {
                    ForEach(vm.edges) { edge in
                        if let source = vm.nodes.first(where: { $0.id == edge.sourceNodeId }),
                           let target = vm.nodes.first(where: { $0.id == edge.targetNodeId }) {
                            EdgeRenderer(
                                edge: edge,
                                sourceNode: source,
                                targetNode: target,
                                isSelected: vm.selectedEdgeId == edge.id,
                                onSelect: {
                                    vm.selectedNodeId = nil
                                    vm.selectedEdgeId = edge.id
                                }
                            )
                        }
                    }

                    ForEach(vm.nodes) { node in
                        NodeView(
                            node: node,
                            isSelected: vm.selectedNodeId == node.id,
                            isSearchHighlighted: highlightedNodeIds.contains(node.id ?? -1),
                            onSelect: {
                                vm.selectedEdgeId = nil
                                vm.selectedNodeId = node.id
                            },
                            onMove: { delta in
                                guard let id = node.id else { return }
                                try? vm.moveNode(id: id, delta: delta)
                            },
                            onEditText: { text in
                                guard let id = node.id else { return }
                                try? vm.updateNodeText(id: id, text: text)
                            }
                        )
                    }
                }
                .scaleEffect(zoom)
                .offset(x: pan.width, y: pan.height)
            }
            .clipped()
        }
    }

    private func screenToCanvas(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: (point.x - size.width / 2 - pan.width) / zoom + size.width / 2,
            y: (point.y - size.height / 2 - pan.height) / zoom + size.height / 2
        )
    }
}
