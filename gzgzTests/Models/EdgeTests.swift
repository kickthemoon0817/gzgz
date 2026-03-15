import XCTest
@testable import gzgz

final class EdgeTests: XCTestCase {
    func testEdgeCreation() {
        let edge = Edge(canvasId: 1, sourceNodeId: 1, targetNodeId: 2)
        XCTAssertEqual(edge.sourceNodeId, 1)
        XCTAssertEqual(edge.targetNodeId, 2)
        XCTAssertNil(edge.label)
        XCTAssertEqual(edge.relationshipType, "related")
    }

    func testEdgeWithType() {
        let edge = Edge(
            canvasId: 1,
            sourceNodeId: 1,
            targetNodeId: 2,
            relationshipType: "depends_on",
            label: "blocks"
        )
        XCTAssertEqual(edge.relationshipType, "depends_on")
        XCTAssertEqual(edge.label, "blocks")
    }
}
