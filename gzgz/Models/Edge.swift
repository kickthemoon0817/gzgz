import Foundation
import GRDB

struct Edge: Identifiable, Equatable, Hashable {
    var id: Int64?
    var canvasId: Int64
    var sourceNodeId: Int64
    var targetNodeId: Int64
    var relationshipType: String
    var label: String?
    var createdAt: Date

    init(
        id: Int64? = nil,
        canvasId: Int64,
        sourceNodeId: Int64,
        targetNodeId: Int64,
        relationshipType: String = "related",
        label: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.canvasId = canvasId
        self.sourceNodeId = sourceNodeId
        self.targetNodeId = targetNodeId
        self.relationshipType = relationshipType
        self.label = label
        self.createdAt = createdAt
    }
}

extension Edge: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "edges"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
