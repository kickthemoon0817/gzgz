import Foundation
import GRDB

struct AppDatabase {
    let writer: DatabaseWriter

    var reader: DatabaseReader { writer }

    init(_ writer: DatabaseWriter) throws {
        self.writer = writer
        try migrator.migrate(writer)
    }

    static func inMemory() throws -> AppDatabase {
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        let writer = try DatabaseQueue(configuration: config)
        return try AppDatabase(writer)
    }

    static func onDisk() throws -> AppDatabase {
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        let url = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("gzgz", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let dbPath = url.appendingPathComponent("gzgz.sqlite").path
        let writer = try DatabaseQueue(path: dbPath, configuration: config)
        return try AppDatabase(writer)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1") { db in
            try db.create(table: "canvases") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull().defaults(to: "Untitled")
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: "thought_nodes") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("canvasId", .integer).notNull()
                    .indexed()
                    .references("canvases", onDelete: .cascade)
                t.column("text", .text).notNull().defaults(to: "")
                t.column("x", .double).notNull()
                t.column("y", .double).notNull()
                t.column("width", .double).notNull().defaults(to: 160)
                t.column("height", .double).notNull().defaults(to: 60)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: "edges") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("canvasId", .integer).notNull()
                    .indexed()
                    .references("canvases", onDelete: .cascade)
                t.column("sourceNodeId", .integer).notNull()
                    .references("thought_nodes", onDelete: .cascade)
                t.column("targetNodeId", .integer).notNull()
                    .references("thought_nodes", onDelete: .cascade)
                t.column("relationshipType", .text).notNull().defaults(to: "related")
                t.column("label", .text)
                t.column("createdAt", .datetime).notNull()
            }
        }

        return migrator
    }
}
