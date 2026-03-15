import XCTest
@testable import gzgz

final class HistoryManagerTests: XCTestCase {
    func testRecordAndUndo() {
        let history = HistoryManager()
        history.record(.createNode(id: 1, canvasId: 1, text: "", x: 0, y: 0))
        XCTAssertEqual(history.entries.count, 1)
        XCTAssertTrue(history.canUndo)
        XCTAssertFalse(history.canRedo)

        let undone = history.undo()
        XCTAssertNotNil(undone)
        XCTAssertFalse(history.canUndo)
        XCTAssertTrue(history.canRedo)
    }

    func testRedo() {
        let history = HistoryManager()
        history.record(.createNode(id: 1, canvasId: 1, text: "", x: 0, y: 0))
        _ = history.undo()

        let redone = history.redo()
        XCTAssertNotNil(redone)
        XCTAssertTrue(history.canUndo)
        XCTAssertFalse(history.canRedo)
    }

    func testNewActionClearsRedoStack() {
        let history = HistoryManager()
        history.record(.createNode(id: 1, canvasId: 1, text: "", x: 0, y: 0))
        _ = history.undo()
        history.record(.createNode(id: 2, canvasId: 1, text: "", x: 100, y: 100))
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.entries.count, 1)
    }

    func testJumpToEntry() {
        let history = HistoryManager()
        history.record(.createNode(id: 1, canvasId: 1, text: "", x: 0, y: 0))
        history.record(.moveNode(id: 1, fromX: 0, fromY: 0, toX: 50, toY: 50))
        history.record(.updateText(id: 1, oldText: "", newText: "Hello"))

        let actions = history.jumpTo(index: 0)
        XCTAssertEqual(actions.count, 2)
    }
}
