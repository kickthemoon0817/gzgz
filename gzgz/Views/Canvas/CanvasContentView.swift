import SwiftUI
import AppKit

struct CanvasContentView: View {
    @Bindable var vm: CanvasViewModel
    var highlightedNodeIds: Set<Int64> = []

    @State private var zoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero
    @State private var lastZoom: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Sketchbook paper background (no hit testing)
                SketchRenderer.paperBackground()
                    .allowsHitTesting(false)

                // Layer 2: Background tap target — BEHIND nodes
                // Only receives taps that miss all nodes (ZStack hit tests top-down)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { location in
                        let canvasPoint = screenToCanvas(location, in: geometry.size)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            try? vm.createNode(at: canvasPoint)
                        }
                    }
                    .onTapGesture(count: 1) { _ in
                        vm.clearSelection()
                    }

                // Layer 3: Nodes and edges (ON TOP — their taps take priority)
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
            // Trackpad scroll + pinch (NSEvent monitors, passes clicks through)
            .overlay {
                TrackpadOverlay(
                    onScroll: { delta in
                        pan = CGSize(width: pan.width + delta.width, height: pan.height + delta.height)
                    },
                    onMagnify: { magnification, cursorInWindow in
                        let newZoom = max(0.1, min(5.0, zoom * (1.0 + magnification)))
                        let scale = newZoom / zoom
                        let cx = cursorInWindow.x - geometry.size.width / 2
                        let cy = cursorInWindow.y - geometry.size.height / 2
                        pan = CGSize(
                            width: pan.width - (cx - pan.width) * (scale - 1),
                            height: pan.height - (cy - pan.height) * (scale - 1)
                        )
                        zoom = newZoom
                    }
                )
                .allowsHitTesting(false)
            }
        }
    }

    private func screenToCanvas(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: (point.x - size.width / 2 - pan.width) / zoom + size.width / 2,
            y: (point.y - size.height / 2 - pan.height) / zoom + size.height / 2
        )
    }
}

// MARK: - Trackpad NSView (scroll + pinch via event monitors, no mouse handling)

struct TrackpadOverlay: NSViewRepresentable {
    let onScroll: (CGSize) -> Void
    let onMagnify: (CGFloat, CGPoint) -> Void

    func makeNSView(context: Context) -> TrackpadNSView {
        let view = TrackpadNSView()
        view.onScroll = onScroll
        view.onMagnify = onMagnify
        return view
    }

    func updateNSView(_ nsView: TrackpadNSView, context: Context) {
        nsView.onScroll = onScroll
        nsView.onMagnify = onMagnify
    }
}

class TrackpadNSView: NSView {
    var onScroll: ((CGSize) -> Void)?
    var onMagnify: ((CGFloat, CGPoint) -> Void)?

    private var scrollMonitor: Any?
    private var magnifyMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setupMonitors()
    }

    private func setupMonitors() {
        removeMonitors()

        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, let window = self.window, event.window == window else { return event }
            let dx = event.scrollingDeltaX
            let dy = event.scrollingDeltaY
            if abs(dx) > 0.01 || abs(dy) > 0.01 {
                DispatchQueue.main.async {
                    self.onScroll?(CGSize(width: dx, height: dy))
                }
            }
            return event
        }

        magnifyMonitor = NSEvent.addLocalMonitorForEvents(matching: .magnify) { [weak self] event in
            guard let self, let window = self.window, event.window == window else { return event }
            let location = self.convert(event.locationInWindow, from: nil)
            let flippedY = self.bounds.height - location.y
            DispatchQueue.main.async {
                self.onMagnify?(event.magnification, CGPoint(x: location.x, y: flippedY))
            }
            return event
        }
    }

    private func removeMonitors() {
        if let m = scrollMonitor { NSEvent.removeMonitor(m); scrollMonitor = nil }
        if let m = magnifyMonitor { NSEvent.removeMonitor(m); magnifyMonitor = nil }
    }

    override func removeFromSuperview() {
        removeMonitors()
        super.removeFromSuperview()
    }

    deinit {
        removeMonitors()
    }
}
