import SwiftUI
import AppKit

struct CanvasContentView: View {
    @Bindable var vm: CanvasViewModel
    var highlightedNodeIds: Set<Int64> = []

    @State private var zoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sketchbook paper texture background
                SketchRenderer.paperTexture(in: geometry.size)
                    .allowsHitTesting(false)

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

                // Invisible event capture layer for scroll & pinch
                CanvasGestureOverlay(
                    onScroll: { delta in
                        pan = CGSize(
                            width: pan.width + delta.width,
                            height: pan.height + delta.height
                        )
                    },
                    onMagnify: { magnification, location in
                        let newZoom = max(0.1, min(5.0, zoom * (1.0 + magnification)))
                        let scale = newZoom / zoom

                        // Zoom toward cursor position
                        let cursorX = location.x - geometry.size.width / 2
                        let cursorY = location.y - geometry.size.height / 2
                        let newPanW = pan.width - (cursorX - pan.width) * (scale - 1)
                        let newPanH = pan.height - (cursorY - pan.height) * (scale - 1)

                        zoom = newZoom
                        pan = CGSize(width: newPanW, height: newPanH)
                    },
                    onDoubleClick: { location in
                        let canvasPoint = screenToCanvas(location, in: geometry.size)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            try? vm.createNode(at: canvasPoint)
                        }
                    },
                    onClick: {
                        vm.clearSelection()
                    }
                )
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

// MARK: - Native macOS gesture capture

struct CanvasGestureOverlay: NSViewRepresentable {
    let onScroll: (CGSize) -> Void
    let onMagnify: (CGFloat, CGPoint) -> Void
    let onDoubleClick: (CGPoint) -> Void
    let onClick: () -> Void

    func makeNSView(context: Context) -> CanvasGestureNSView {
        let view = CanvasGestureNSView()
        view.onScroll = onScroll
        view.onMagnify = onMagnify
        view.onDoubleClick = onDoubleClick
        view.onClick = onClick
        return view
    }

    func updateNSView(_ nsView: CanvasGestureNSView, context: Context) {
        nsView.onScroll = onScroll
        nsView.onMagnify = onMagnify
        nsView.onDoubleClick = onDoubleClick
        nsView.onClick = onClick
    }
}

class CanvasGestureNSView: NSView {
    var onScroll: ((CGSize) -> Void)?
    var onMagnify: ((CGFloat, CGPoint) -> Void)?
    var onDoubleClick: ((CGPoint) -> Void)?
    var onClick: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true } // Match SwiftUI coordinate system

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        // Enable magnification gesture
        self.allowedTouchTypes = [.indirect]
    }

    override func scrollWheel(with event: NSEvent) {
        // Two-finger trackpad scroll
        let dx = event.scrollingDeltaX
        let dy = event.scrollingDeltaY
        if abs(dx) > 0.01 || abs(dy) > 0.01 {
            onScroll?(CGSize(width: dx, height: dy))
        }
    }

    override func magnify(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        onMagnify?(event.magnification, CGPoint(x: location.x, y: location.y))
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            let location = convert(event.locationInWindow, from: nil)
            onDoubleClick?(CGPoint(x: location.x, y: location.y))
        } else if event.clickCount == 1 {
            // Delay single click to avoid firing on double-click
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                if NSApp.currentEvent?.clickCount != 2 {
                    self?.onClick?()
                }
            }
        }
    }

    // Pass through events to SwiftUI views underneath for node interactions
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Only capture if no SwiftUI subview wants the event
        // Return self to capture scroll/magnify, but let clicks fall through to nodes
        return self
    }
}
