import XCTest
@testable import gzgz

final class SearchViewModelTests: XCTestCase {
    func testSearchFindsMatchingNodes() throws {
        let store = try Store(database: .inMemory())
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)

        var n1 = ThoughtNode(canvasId: canvas.id!, text: "Build an app", x: 0, y: 0)
        var n2 = ThoughtNode(canvasId: canvas.id!, text: "Design the UI", x: 100, y: 0)
        var n3 = ThoughtNode(canvasId: canvas.id!, text: "Ship it", x: 200, y: 0)
        try store.saveNode(&n1)
        try store.saveNode(&n2)
        try store.saveNode(&n3)

        let vm = SearchViewModel(store: store)
        try vm.search(query: "the")
        XCTAssertEqual(vm.results.count, 1) // "Design the UI"
    }

    func testEmptyQueryClearsResults() throws {
        let store = try Store(database: .inMemory())
        let vm = SearchViewModel(store: store)
        try vm.search(query: "")
        XCTAssertTrue(vm.results.isEmpty)
    }
}
