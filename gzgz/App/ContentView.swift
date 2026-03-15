import SwiftUI

struct ContentView: View {
    @State var vm: CanvasViewModel
    @State private var searchVM: SearchViewModel
    @State private var history = HistoryManager()
    @State private var showHistory = false

    init(vm: CanvasViewModel) {
        self._vm = State(initialValue: vm)
        self._searchVM = State(initialValue: SearchViewModel(store: vm.store))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            CanvasSidebar(vm: vm)
            Divider()

            // Main canvas area
            ZStack {
                CanvasContentView(
                    vm: vm,
                    highlightedNodeIds: searchVM.highlightedNodeIds
                )

                // Search overlay
                VStack {
                    SearchOverlay(vm: searchVM) { node in
                        vm.selectedNodeId = node.id
                    }
                    .padding(.top, 60)
                    Spacer()
                }

                // History panel toggle
                HStack {
                    Spacer()
                    if showHistory {
                        HistoryPanel(history: history) { index in
                            let actions = history.jumpTo(index: index)
                            for action in actions {
                                applyHistoryAction(action)
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.gzBackground)
        .task {
            try? vm.loadOrCreateDefaultCanvas()
        }
        // Keyboard shortcuts via hidden buttons
        .overlay {
            VStack {
                Button("Search") { searchVM.toggle() }
                    .keyboardShortcut("k", modifiers: .command)
                Button("Undo") {
                    if let action = history.undo() { applyHistoryAction(action) }
                }
                .keyboardShortcut("z", modifiers: .command)
                Button("Redo") {
                    if let action = history.redo() { applyHistoryAction(action) }
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                Button("History") { showHistory.toggle() }
                    .keyboardShortcut("y", modifiers: .command)
                Button("Delete") {
                    withAnimation(.easeOut(duration: 0.2)) {
                        try? vm.deleteSelected()
                    }
                }
                .keyboardShortcut(.delete, modifiers: [])
                Button("DeleteForward") {
                    withAnimation(.easeOut(duration: 0.2)) {
                        try? vm.deleteSelected()
                    }
                }
                .keyboardShortcut(.deleteForward, modifiers: [])
            }
            .frame(width: 0, height: 0)
            .opacity(0)
            .allowsHitTesting(false)
        }
    }

    private func applyHistoryAction(_ action: HistoryAction) {
        switch action {
        case .createNode(let id, let canvasId, let text, let x, let y):
            try? vm.restoreNode(id: id, canvasId: canvasId, text: text, x: x, y: y)
        case .deleteNode(let id, _, _, _, _, _, _):
            try? vm.deleteNode(id: id)
        case .moveNode(let id, _, _, let toX, let toY):
            if let index = vm.nodes.firstIndex(where: { $0.id == id }) {
                let dx = toX - vm.nodes[index].x
                let dy = toY - vm.nodes[index].y
                try? vm.moveNode(id: id, delta: CGSize(width: dx, height: dy))
            }
        case .updateText(let id, _, let newText):
            try? vm.updateNodeText(id: id, text: newText)
        case .createEdge(_, _, let sourceId, let targetId, let type, let label):
            try? vm.createEdge(sourceId: sourceId, targetId: targetId, type: type, label: label)
        case .deleteEdge(let id, _, _, _, _, _):
            try? vm.deleteEdge(id: id)
        }
    }
}
