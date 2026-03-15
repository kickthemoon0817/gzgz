import Foundation

enum HistoryAction {
    case createNode(id: Int64, canvasId: Int64, text: String, x: Double, y: Double)
    case deleteNode(id: Int64, canvasId: Int64, text: String, x: Double, y: Double, width: Double, height: Double)
    case moveNode(id: Int64, fromX: Double, fromY: Double, toX: Double, toY: Double)
    case updateText(id: Int64, oldText: String, newText: String)
    case createEdge(id: Int64, canvasId: Int64, sourceId: Int64, targetId: Int64, type: String, label: String?)
    case deleteEdge(id: Int64, canvasId: Int64, sourceId: Int64, targetId: Int64, type: String, label: String?)

    var displayName: String {
        switch self {
        case .createNode: return "Create node"
        case .deleteNode: return "Delete node"
        case .moveNode: return "Move node"
        case .updateText(_, _, let newText): return "Edit: \"\(String(newText.prefix(20)))\""
        case .createEdge: return "Create connection"
        case .deleteEdge: return "Delete connection"
        }
    }

    var inverse: HistoryAction {
        switch self {
        case .createNode(let id, let canvasId, let text, let x, let y):
            return .deleteNode(id: id, canvasId: canvasId, text: text, x: x, y: y, width: 160, height: 60)
        case .deleteNode(let id, let canvasId, let text, let x, let y, _, _):
            return .createNode(id: id, canvasId: canvasId, text: text, x: x, y: y)
        case .moveNode(let id, let fromX, let fromY, let toX, let toY):
            return .moveNode(id: id, fromX: toX, fromY: toY, toX: fromX, toY: fromY)
        case .updateText(let id, let oldText, let newText):
            return .updateText(id: id, oldText: newText, newText: oldText)
        case .createEdge(let id, let canvasId, let s, let t, let type, let label):
            return .deleteEdge(id: id, canvasId: canvasId, sourceId: s, targetId: t, type: type, label: label)
        case .deleteEdge(let id, let canvasId, let s, let t, let type, let label):
            return .createEdge(id: id, canvasId: canvasId, sourceId: s, targetId: t, type: type, label: label)
        }
    }
}

@Observable
final class HistoryManager {
    private(set) var entries: [HistoryAction] = []
    private var redoStack: [HistoryAction] = []
    private(set) var currentIndex: Int = -1

    var canUndo: Bool { currentIndex >= 0 }
    var canRedo: Bool { !redoStack.isEmpty }

    func record(_ action: HistoryAction) {
        currentIndex += 1
        if currentIndex < entries.count {
            entries.removeSubrange(currentIndex...)
        }
        entries.append(action)
        redoStack.removeAll()
    }

    func undo() -> HistoryAction? {
        guard canUndo else { return nil }
        let action = entries[currentIndex]
        redoStack.append(action)
        currentIndex -= 1
        return action.inverse
    }

    func redo() -> HistoryAction? {
        guard canRedo else { return nil }
        let action = redoStack.removeLast()
        currentIndex += 1
        return action
    }

    func jumpTo(index: Int) -> [HistoryAction] {
        var actions: [HistoryAction] = []
        if index < currentIndex {
            while currentIndex > index {
                if let action = undo() {
                    actions.append(action)
                }
            }
        } else if index > currentIndex {
            while currentIndex < index {
                if let action = redo() {
                    actions.append(action)
                }
            }
        }
        return actions
    }

    func clear() {
        entries.removeAll()
        redoStack.removeAll()
        currentIndex = -1
    }
}
