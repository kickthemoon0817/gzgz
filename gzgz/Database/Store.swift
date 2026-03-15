import Foundation
import GRDB

final class Store {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    // MARK: - Canvas

    func saveCanvas(_ canvas: inout ThoughtCanvas) throws {
        try database.writer.write { db in
            try canvas.save(db)
        }
    }

    func fetchCanvases() throws -> [ThoughtCanvas] {
        try database.reader.read { db in
            try ThoughtCanvas.order(Column("createdAt").asc).fetchAll(db)
        }
    }

    func deleteCanvas(id: Int64) throws {
        try database.writer.write { db in
            _ = try ThoughtCanvas.deleteOne(db, id: id)
        }
    }

    // MARK: - Nodes

    func saveNode(_ node: inout ThoughtNode) throws {
        try database.writer.write { db in
            try node.save(db)
        }
    }

    func fetchNodes(canvasId: Int64) throws -> [ThoughtNode] {
        try database.reader.read { db in
            try ThoughtNode
                .filter(Column("canvasId") == canvasId)
                .fetchAll(db)
        }
    }

    func deleteNode(id: Int64) throws {
        try database.writer.write { db in
            _ = try ThoughtNode.deleteOne(db, id: id)
        }
    }

    // MARK: - Edges

    func saveEdge(_ edge: inout Edge) throws {
        try database.writer.write { db in
            try edge.save(db)
        }
    }

    func fetchEdges(canvasId: Int64) throws -> [Edge] {
        try database.reader.read { db in
            try Edge
                .filter(Column("canvasId") == canvasId)
                .fetchAll(db)
        }
    }

    func deleteEdge(id: Int64) throws {
        try database.writer.write { db in
            _ = try Edge.deleteOne(db, id: id)
        }
    }

    // MARK: - Search

    func searchNodes(query: String) throws -> [ThoughtNode] {
        let pattern = "%\(query)%"
        return try database.reader.read { db in
            try ThoughtNode.filter(sql: "text LIKE ?", arguments: [pattern]).fetchAll(db)
        }
    }
}
