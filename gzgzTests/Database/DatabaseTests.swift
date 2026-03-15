import XCTest
import GRDB
@testable import gzgz

final class DatabaseTests: XCTestCase {
    func testInMemoryDatabaseCreation() throws {
        let db = try AppDatabase.inMemory()
        XCTAssertNotNil(db)
    }

    func testMigrations() throws {
        let db = try AppDatabase.inMemory()
        try db.reader.read { db in
            let tables = try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
            XCTAssertTrue(tables.contains("thought_nodes"))
            XCTAssertTrue(tables.contains("edges"))
            XCTAssertTrue(tables.contains("canvases"))
        }
    }
}
