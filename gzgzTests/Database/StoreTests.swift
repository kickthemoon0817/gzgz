import XCTest
import GRDB
@testable import gzgz

final class StoreTests: XCTestCase {
    var store: Store!

    override func setUp() async throws {
        store = try Store(database: .inMemory())
    }

    func testCreateAndFetchCanvas() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)
        XCTAssertNotNil(canvas.id)

        let fetched = try store.fetchCanvases()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Test")
    }

    func testCreateAndFetchNode() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)

        var node = ThoughtNode(canvasId: canvas.id!, text: "Idea", x: 50, y: 100)
        try store.saveNode(&node)
        XCTAssertNotNil(node.id)

        let nodes = try store.fetchNodes(canvasId: canvas.id!)
        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes.first?.text, "Idea")
    }

    func testCreateAndFetchEdge() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)

        var node1 = ThoughtNode(canvasId: canvas.id!, text: "A", x: 0, y: 0)
        var node2 = ThoughtNode(canvasId: canvas.id!, text: "B", x: 100, y: 100)
        try store.saveNode(&node1)
        try store.saveNode(&node2)

        var edge = Edge(canvasId: canvas.id!, sourceNodeId: node1.id!, targetNodeId: node2.id!)
        try store.saveEdge(&edge)
        XCTAssertNotNil(edge.id)

        let edges = try store.fetchEdges(canvasId: canvas.id!)
        XCTAssertEqual(edges.count, 1)
    }

    func testDeleteNode() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)

        var node = ThoughtNode(canvasId: canvas.id!, text: "Delete me", x: 0, y: 0)
        try store.saveNode(&node)
        XCTAssertEqual(try store.fetchNodes(canvasId: canvas.id!).count, 1)

        try store.deleteNode(id: node.id!)
        XCTAssertEqual(try store.fetchNodes(canvasId: canvas.id!).count, 0)
    }

    func testDeleteNodeCascadesEdges() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)

        var node1 = ThoughtNode(canvasId: canvas.id!, text: "A", x: 0, y: 0)
        var node2 = ThoughtNode(canvasId: canvas.id!, text: "B", x: 100, y: 0)
        try store.saveNode(&node1)
        try store.saveNode(&node2)

        var edge = Edge(canvasId: canvas.id!, sourceNodeId: node1.id!, targetNodeId: node2.id!)
        try store.saveEdge(&edge)
        XCTAssertEqual(try store.fetchEdges(canvasId: canvas.id!).count, 1)

        try store.deleteNode(id: node1.id!)
        XCTAssertEqual(try store.fetchEdges(canvasId: canvas.id!).count, 0)
    }

    func testSearchNodes() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)

        var n1 = ThoughtNode(canvasId: canvas.id!, text: "Build the app", x: 0, y: 0)
        var n2 = ThoughtNode(canvasId: canvas.id!, text: "Design the UI", x: 100, y: 0)
        var n3 = ThoughtNode(canvasId: canvas.id!, text: "Ship it", x: 200, y: 0)
        try store.saveNode(&n1)
        try store.saveNode(&n2)
        try store.saveNode(&n3)

        let results = try store.searchNodes(query: "the")
        XCTAssertEqual(results.count, 2)
    }
}
