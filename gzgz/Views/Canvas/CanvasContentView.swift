import SwiftUI

struct CanvasContentView: View {
    @Bindable var vm: CanvasViewModel
    var highlightedNodeIds: Set<Int64> = []

    @State private var zoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero
    @State private var lastPan: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background — tap to deselect, double-tap to create node
                Color.gzCanvasBackground
                    .onTapGesture(count: 2) { location in
                        let canvasPoint = screenToCanvas(location, in: geometry.size)
                        try? vm.createNode(at: canvasPoint)
                    }
                    .onTapGesture(count: 1) { _ in
                        vm.clearSelection()
                    }

                // Canvas content with transform
                ZStack {
                    // Edges
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

                    // Nodes
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
                                try? vm.moveNode(id: node.id!, delta: delta)
                            },
                            onEditText: { text in
                                try? vm.updateNodeText(id: node.id!, text: text)
                            }
                        )
                    }
                }
                .scaleEffect(zoom)
                .offset(x: pan.width, y: pan.height)
            }
            .gesture(panGesture)
            .gesture(zoomGesture)
        }
    }

    private func screenToCanvas(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: (point.x - size.width / 2 - pan.width) / zoom + size.width / 2,
            y: (point.y - size.height / 2 - pan.height) / zoom + size.height / 2
        )
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .modifiers(.command)
            .onChanged { value in
                pan = CGSize(
                    width: lastPan.width + value.translation.width,
                    height: lastPan.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastPan = pan
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = max(0.1, min(5.0, value.magnification))
            }
    }
}
