import Foundation
import GRDB

struct ThoughtCanvas: Identifiable, Equatable, Hashable {
    var id: Int64?
    var name: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: Int64? = nil,
        name: String = "Untitled",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension ThoughtCanvas: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "canvases"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
