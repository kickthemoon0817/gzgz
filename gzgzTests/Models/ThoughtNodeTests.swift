import XCTest
@testable import gzgz

final class ThoughtNodeTests: XCTestCase {
    func testNodeCreation() {
        let node = ThoughtNode(canvasId: 1, text: "Hello", x: 100, y: 200)
        XCTAssertEqual(node.text, "Hello")
        XCTAssertEqual(node.x, 100)
        XCTAssertEqual(node.y, 200)
        XCTAssertEqual(node.canvasId, 1)
        XCTAssertEqual(node.width, 160)
        XCTAssertEqual(node.height, 60)
    }

    func testNodeDefaultDimensions() {
        let node = ThoughtNode(canvasId: 1, text: "", x: 0, y: 0)
        XCTAssertEqual(node.width, 160)
        XCTAssertEqual(node.height, 60)
    }
}
