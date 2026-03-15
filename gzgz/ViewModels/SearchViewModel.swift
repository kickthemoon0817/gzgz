import Foundation

@Observable
final class SearchViewModel {
    private let store: Store

    var query: String = ""
    var results: [ThoughtNode] = []
    var isVisible = false
    var selectedResultIndex: Int = 0

    init(store: Store) {
        self.store = store
    }

    func toggle() {
        isVisible.toggle()
        if !isVisible {
            query = ""
            results = []
            selectedResultIndex = 0
        }
    }

    func search(query: String) throws {
        self.query = query
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            results = []
            return
        }
        results = try store.searchNodes(query: query)
        selectedResultIndex = 0
    }

    func selectNext() {
        if !results.isEmpty {
            selectedResultIndex = (selectedResultIndex + 1) % results.count
        }
    }

    func selectPrevious() {
        if !results.isEmpty {
            selectedResultIndex = (selectedResultIndex - 1 + results.count) % results.count
        }
    }

    var selectedResult: ThoughtNode? {
        guard !results.isEmpty, selectedResultIndex < results.count else { return nil }
        return results[selectedResultIndex]
    }

    var highlightedNodeIds: Set<Int64> {
        Set(results.compactMap(\.id))
    }
}
