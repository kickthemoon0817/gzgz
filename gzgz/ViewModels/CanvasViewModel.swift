import SwiftUI

@Observable
final class CanvasViewModel {
    let store: Store

    var nodes: [ThoughtNode] = []
    var edges: [Edge] = []
    var canvases: [ThoughtCanvas] = []
    var currentCanvasId: Int64?
    var selectedNodeId: Int64?
    var selectedEdgeId: Int64?

    // Connection drawing state
    var isDrawingEdge = false
    var edgeSourceId: Int64?
    var edgeDragPoint: CGPoint?

    init(store: Store) {
        self.store = store
    }

    func loadOrCreateDefaultCanvas() throws {
        canvases = try store.fetchCanvases()
        if canvases.isEmpty {
            var canvas = ThoughtCanvas(name: "Untitled")
            try store.saveCanvas(&canvas)
            canvases = [canvas]
        }
        currentCanvasId = canvases.first?.id
        try reload()
    }

    func reload() throws {
        guard let canvasId = currentCanvasId else { return }
        nodes = try store.fetchNodes(canvasId: canvasId)
        edges = try store.fetchEdges(canvasId: canvasId)
    }

    // MARK: - Nodes

    func createNode(at point: CGPoint) throws {
        guard let canvasId = currentCanvasId else { return }
        var node = ThoughtNode(
            canvasId: canvasId,
            text: "",
            x: point.x - 80,
            y: point.y - 30
        )
        try store.saveNode(&node)
        nodes.append(node)
        selectedNodeId = node.id
    }

    func updateNodeText(id: Int64, text: String) throws {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[index].text = text
        nodes[index].updatedAt = Date()
        try store.saveNode(&nodes[index])
    }

    func moveNode(id: Int64, delta: CGSize) throws {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[index].x += delta.width
        nodes[index].y += delta.height
        nodes[index].updatedAt = Date()
        try store.saveNode(&nodes[index])
    }

    func deleteNode(id: Int64) throws {
        try store.deleteNode(id: id)
        nodes.removeAll { $0.id == id }
        edges.removeAll { $0.sourceNodeId == id || $0.targetNodeId == id }
        if selectedNodeId == id { selectedNodeId = nil }
    }

    // MARK: - Edges

    func createEdge(sourceId: Int64, targetId: Int64, type: String = "related", label: String? = nil) throws {
        guard let canvasId = currentCanvasId else { return }
        guard sourceId != targetId else { return }
        guard !edges.contains(where: { $0.sourceNodeId == sourceId && $0.targetNodeId == targetId }) else { return }

        var edge = Edge(
            canvasId: canvasId,
            sourceNodeId: sourceId,
            targetNodeId: targetId,
            relationshipType: type,
            label: label
        )
        try store.saveEdge(&edge)
        edges.append(edge)
    }

    func deleteEdge(id: Int64) throws {
        try store.deleteEdge(id: id)
        edges.removeAll { $0.id == id }
        if selectedEdgeId == id { selectedEdgeId = nil }
    }

    // MARK: - Selection

    func clearSelection() {
        selectedNodeId = nil
        selectedEdgeId = nil
    }

    func deleteSelected() throws {
        if let nodeId = selectedNodeId {
            try deleteNode(id: nodeId)
        } else if let edgeId = selectedEdgeId {
            try deleteEdge(id: edgeId)
        }
    }

    // MARK: - Canvas Management

    func createCanvas(name: String) throws {
        var canvas = ThoughtCanvas(name: name)
        try store.saveCanvas(&canvas)
        canvases.append(canvas)
        currentCanvasId = canvas.id
        try reload()
    }

    func switchCanvas(id: Int64) throws {
        currentCanvasId = id
        clearSelection()
        try reload()
    }

    func renameCanvas(id: Int64, name: String) throws {
        guard let index = canvases.firstIndex(where: { $0.id == id }) else { return }
        canvases[index].name = name
        canvases[index].updatedAt = Date()
        try store.saveCanvas(&canvases[index])
    }
}
