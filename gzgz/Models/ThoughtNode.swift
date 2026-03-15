import Foundation
import GRDB

struct ThoughtNode: Identifiable, Equatable, Hashable {
    var id: Int64?
    var canvasId: Int64
    var text: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: Int64? = nil,
        canvasId: Int64,
        text: String,
        x: Double,
        y: Double,
        width: Double = 160,
        height: Double = 60,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.canvasId = canvasId
        self.text = text
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension ThoughtNode: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "thought_nodes"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
