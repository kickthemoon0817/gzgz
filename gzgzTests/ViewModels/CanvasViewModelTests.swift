import XCTest
@testable import gzgz

final class CanvasViewModelTests: XCTestCase {
    var vm: CanvasViewModel!

    override func setUp() async throws {
        let store = try Store(database: .inMemory())
        vm = CanvasViewModel(store: store)
        try vm.loadOrCreateDefaultCanvas()
    }

    func testCreateNode() throws {
        try vm.createNode(at: CGPoint(x: 100, y: 200))
        XCTAssertEqual(vm.nodes.count, 1)
        XCTAssertEqual(vm.nodes.first?.x, 20)  // 100 - 80 (centered)
        XCTAssertEqual(vm.nodes.first?.y, 170)  // 200 - 30 (centered)
    }

    func testUpdateNodeText() throws {
        try vm.createNode(at: CGPoint(x: 0, y: 0))
        let node = vm.nodes.first!
        try vm.updateNodeText(id: node.id!, text: "Hello")
        XCTAssertEqual(vm.nodes.first?.text, "Hello")
    }

    func testMoveNode() throws {
        try vm.createNode(at: CGPoint(x: 100, y: 100))
        let node = vm.nodes.first!
        let originalX = node.x
        let originalY = node.y
        try vm.moveNode(id: node.id!, delta: CGSize(width: 50, height: -30))
        XCTAssertEqual(vm.nodes.first?.x, originalX + 50)
        XCTAssertEqual(vm.nodes.first?.y, originalY - 30)
    }

    func testDeleteNode() throws {
        try vm.createNode(at: CGPoint(x: 0, y: 0))
        let node = vm.nodes.first!
        try vm.deleteNode(id: node.id!)
        XCTAssertTrue(vm.nodes.isEmpty)
    }

    func testCreateEdge() throws {
        try vm.createNode(at: CGPoint(x: 0, y: 0))
        try vm.createNode(at: CGPoint(x: 200, y: 200))
        let n1 = vm.nodes[0]
        let n2 = vm.nodes[1]
        try vm.createEdge(sourceId: n1.id!, targetId: n2.id!)
        XCTAssertEqual(vm.edges.count, 1)
    }

    func testDeleteNodeRemovesEdges() throws {
        try vm.createNode(at: CGPoint(x: 0, y: 0))
        try vm.createNode(at: CGPoint(x: 200, y: 200))
        let n1 = vm.nodes[0]
        let n2 = vm.nodes[1]
        try vm.createEdge(sourceId: n1.id!, targetId: n2.id!)
        try vm.deleteNode(id: n1.id!)
        XCTAssertTrue(vm.edges.isEmpty)
    }
}
