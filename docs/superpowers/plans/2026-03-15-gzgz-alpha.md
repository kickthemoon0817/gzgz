# gzgz Alpha Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the alpha SwiftUI app — a blank canvas where users create thought nodes, connect them with edges, and organize visually with Excalidraw-style rendering and Russian Violet theming.

**Architecture:** MVVM with SwiftUI views, a shared data layer using GRDB.swift for SQLite persistence, and a custom Canvas rendering pipeline for sketchy Excalidraw-style graphics. macOS app first, structured for iOS reuse.

**Tech Stack:** Swift 6, SwiftUI, GRDB.swift (SQLite), XcodeGen

---

## Alpha Scope

Core canvas experience only:

- Pure blank canvas with infinite pan/zoom
- Tap-to-create nodes, type text, drag to reposition
- Draw connections between nodes
- Excalidraw-style sketchy rendering (wobbly lines, hand-drawn shapes)
- Russian Violet (`#32174D`) color theme
- SQLite auto-persistence
- `Cmd+K` search
- Undo/redo with operation history panel
- Multiple canvases

**Not in alpha:** voice input, AI integration, MCP server, freehand drawing, iOS build

---

## File Structure

```
gzgz/
├── project.yml                          # XcodeGen spec
├── gzgz/
│   ├── App/
│   │   ├── gzgzApp.swift                # App entry point
│   │   └── ContentView.swift            # Root view: sidebar + canvas
│   ├── Models/
│   │   ├── ThoughtNode.swift            # Node data model (GRDB Record)
│   │   ├── Edge.swift                   # Edge data model (GRDB Record)
│   │   └── ThoughtCanvas.swift          # Canvas data model (GRDB Record)
│   ├── Database/
│   │   ├── Database.swift               # GRDB DatabaseQueue setup + migrations
│   │   └── Store.swift                  # CRUD operations, observation
│   ├── ViewModels/
│   │   ├── CanvasViewModel.swift        # Canvas state, node/edge CRUD, drag logic
│   │   ├── SearchViewModel.swift        # Cmd+K search logic
│   │   └── HistoryManager.swift         # Undo/redo operation stack
│   ├── Views/
│   │   ├── Canvas/
│   │   │   ├── InfiniteCanvas.swift     # Pan/zoom container
│   │   │   ├── NodeView.swift           # Single node rendering + interactions
│   │   │   ├── EdgeRenderer.swift       # Sketchy edge drawing
│   │   │   └── CanvasContentView.swift  # Composes nodes + edges on canvas
│   │   ├── Search/
│   │   │   └── SearchOverlay.swift      # Cmd+K search palette
│   │   ├── History/
│   │   │   └── HistoryPanel.swift       # Photoshop-style history sidebar
│   │   └── Sidebar/
│   │       └── CanvasSidebar.swift      # Canvas list + switcher
│   └── Theme/
│       ├── SketchRenderer.swift         # Wobbly line/shape algorithms
│       ├── Colors.swift                 # Russian Violet palette
│       └── Fonts.swift                  # Handwritten font config
├── gzgzTests/
│   ├── Models/
│   │   ├── ThoughtNodeTests.swift
│   │   └── EdgeTests.swift
│   ├── Database/
│   │   ├── DatabaseTests.swift
│   │   └── StoreTests.swift
│   └── ViewModels/
│       ├── CanvasViewModelTests.swift
│       ├── SearchViewModelTests.swift
│       └── HistoryManagerTests.swift
└── Resources/
    └── Fonts/                           # Bundled handwritten font (if needed)
```

---

## Chunk 1: Project Scaffolding + Data Layer

### Task 1: Project Setup

**Files:**

- Create: `project.yml`
- Create: `gzgz/App/gzgzApp.swift`
- Create: `gzgz/App/ContentView.swift`

- [ ] **Step 1: Install XcodeGen**

Run: `brew install xcodegen`

- [ ] **Step 2: Create project.yml**

```yaml
name: gzgz
options:
  bundleIdPrefix: com.gzgz
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "16.0"
  createIntermediateGroups: true
packages:
  GRDB:
    url: https://github.com/groue/GRDB.swift
    from: "7.0.0"
targets:
  gzgz:
    type: application
    platform: macOS
    sources: [gzgz]
    resources: [Resources]
    dependencies:
      - package: GRDB
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.gzgz.app
        MARKETING_VERSION: "0.1.0"
        CURRENT_PROJECT_VERSION: "1"
        INFOPLIST_KEY_LSApplicationCategoryType: "public.app-category.productivity"
  gzgzTests:
    type: bundle.unit-test
    platform: macOS
    sources: [gzgzTests]
    dependencies:
      - target: gzgz
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.gzgz.tests
```

- [ ] **Step 3: Create app entry point**

Create `gzgz/App/gzgzApp.swift`:

```swift
import SwiftUI

@main
struct gzgzApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
    }
}
```

- [ ] **Step 4: Create placeholder ContentView**

Create `gzgz/App/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("gzgz")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#1a1a2e"))
    }
}
```

- [ ] **Step 5: Generate Xcode project and verify build**

Run: `xcodegen generate && xcodebuild -scheme gzgz -destination 'platform=macOS' build`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: scaffold gzgz macOS app with XcodeGen + GRDB"
```

---

### Task 2: Theme — Colors & Fonts

**Files:**

- Create: `gzgz/Theme/Colors.swift`
- Create: `gzgz/Theme/Fonts.swift`

- [ ] **Step 1: Create color palette**

Create `gzgz/Theme/Colors.swift`:

```swift
import SwiftUI

extension Color {
    // Russian Violet palette
    static let gzPrimary = Color(hex: "#32174D")
    static let gzPrimaryLight = Color(hex: "#4A2570")
    static let gzPrimaryDark = Color(hex: "#1E0E2E")
    static let gzAccent = Color(hex: "#7B4FA2")
    static let gzBackground = Color(hex: "#F5F0F8")
    static let gzCanvasBackground = Color(hex: "#FDFBFE")
    static let gzNodeFill = Color(hex: "#FFFFFF")
    static let gzNodeStroke = Color(hex: "#32174D")
    static let gzEdgeStroke = Color(hex: "#7B4FA2")
    static let gzText = Color(hex: "#1E0E2E")
    static let gzTextSecondary = Color(hex: "#6B5B7B")
    static let gzSelection = Color(hex: "#32174D").opacity(0.15)
    static let gzSearchHighlight = Color(hex: "#FFD700").opacity(0.4)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
```

- [ ] **Step 2: Create font config**

Create `gzgz/Theme/Fonts.swift`:

```swift
import SwiftUI

enum GZFont {
    static func node(_ size: CGFloat = 14) -> Font {
        .system(size: size, design: .rounded)
    }

    static func nodeTitle(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func label(_ size: CGFloat = 12) -> Font {
        .system(size: size, design: .rounded)
    }

    static func search(_ size: CGFloat = 16) -> Font {
        .system(size: size, design: .rounded)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add gzgz/Theme/ && git commit -m "feat: add Russian Violet color palette and font config"
```

---

### Task 3: Data Models

**Files:**

- Create: `gzgz/Models/ThoughtNode.swift`
- Create: `gzgz/Models/Edge.swift`
- Create: `gzgz/Models/ThoughtCanvas.swift`
- Create: `gzgzTests/Models/ThoughtNodeTests.swift`
- Create: `gzgzTests/Models/EdgeTests.swift`

- [ ] **Step 1: Write ThoughtNode model tests**

Create `gzgzTests/Models/ThoughtNodeTests.swift`:

```swift
import XCTest
@testable import gzgz

final class ThoughtNodeTests: XCTestCase {
    func testNodeCreation() {
        let node = ThoughtNode(canvasId: 1, text: "Hello", x: 100, y: 200)
        XCTAssertEqual(node.text, "Hello")
        XCTAssertEqual(node.x, 100)
        XCTAssertEqual(node.y, 200)
        XCTAssertEqual(node.canvasId, 1)
        XCTAssertEqual(node.width, 160)
        XCTAssertEqual(node.height, 60)
    }

    func testNodeDefaultDimensions() {
        let node = ThoughtNode(canvasId: 1, text: "", x: 0, y: 0)
        XCTAssertEqual(node.width, 160)
        XCTAssertEqual(node.height, 60)
    }
}
```

- [ ] **Step 2: Write Edge model tests**

Create `gzgzTests/Models/EdgeTests.swift`:

```swift
import XCTest
@testable import gzgz

final class EdgeTests: XCTestCase {
    func testEdgeCreation() {
        let edge = Edge(canvasId: 1, sourceNodeId: 1, targetNodeId: 2)
        XCTAssertEqual(edge.sourceNodeId, 1)
        XCTAssertEqual(edge.targetNodeId, 2)
        XCTAssertNil(edge.label)
        XCTAssertEqual(edge.relationshipType, "related")
    }

    func testEdgeWithType() {
        let edge = Edge(
            canvasId: 1,
            sourceNodeId: 1,
            targetNodeId: 2,
            relationshipType: "depends_on",
            label: "blocks"
        )
        XCTAssertEqual(edge.relationshipType, "depends_on")
        XCTAssertEqual(edge.label, "blocks")
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `xcodebuild test -scheme gzgz -destination 'platform=macOS'`
Expected: FAIL — models don't exist yet

- [ ] **Step 4: Implement ThoughtNode model**

Create `gzgz/Models/ThoughtNode.swift`:

```swift
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
```

- [ ] **Step 5: Implement Edge model**

Create `gzgz/Models/Edge.swift`:

```swift
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
```

- [ ] **Step 6: Implement ThoughtCanvas model**

Create `gzgz/Models/ThoughtCanvas.swift`:

```swift
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
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `xcodebuild test -scheme gzgz -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add gzgz/Models/ gzgzTests/Models/ && git commit -m "feat: add ThoughtNode, Edge, and ThoughtCanvas data models"
```

---

### Task 4: Database Layer

**Files:**

- Create: `gzgz/Database/Database.swift`
- Create: `gzgz/Database/Store.swift`
- Create: `gzgzTests/Database/DatabaseTests.swift`
- Create: `gzgzTests/Database/StoreTests.swift`

- [ ] **Step 1: Write database tests**

Create `gzgzTests/Database/DatabaseTests.swift`:

```swift
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
```

- [ ] **Step 2: Write store tests**

Create `gzgzTests/Database/StoreTests.swift`:

```swift
import XCTest
import GRDB
@testable import gzgz

final class StoreTests: XCTestCase {
    var store: Store!

    override func setUp() async throws {
        store = try Store(database: .inMemory())
    }

    func testCreateAndFetchCanvas() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)
        XCTAssertNotNil(canvas.id)

        let fetched = try store.fetchCanvases()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Test")
    }

    func testCreateAndFetchNode() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)

        var node = ThoughtNode(canvasId: canvas.id!, text: "Idea", x: 50, y: 100)
        try store.saveNode(&node)
        XCTAssertNotNil(node.id)

        let nodes = try store.fetchNodes(canvasId: canvas.id!)
        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes.first?.text, "Idea")
    }

    func testCreateAndFetchEdge() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)

        var node1 = ThoughtNode(canvasId: canvas.id!, text: "A", x: 0, y: 0)
        var node2 = ThoughtNode(canvasId: canvas.id!, text: "B", x: 100, y: 100)
        try store.saveNode(&node1)
        try store.saveNode(&node2)

        var edge = Edge(canvasId: canvas.id!, sourceNodeId: node1.id!, targetNodeId: node2.id!)
        try store.saveEdge(&edge)
        XCTAssertNotNil(edge.id)

        let edges = try store.fetchEdges(canvasId: canvas.id!)
        XCTAssertEqual(edges.count, 1)
    }

    func testDeleteNode() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)

        var node = ThoughtNode(canvasId: canvas.id!, text: "Delete me", x: 0, y: 0)
        try store.saveNode(&node)
        XCTAssertEqual(try store.fetchNodes(canvasId: canvas.id!).count, 1)

        try store.deleteNode(id: node.id!)
        XCTAssertEqual(try store.fetchNodes(canvasId: canvas.id!).count, 0)
    }

    func testDeleteNodeCascadesEdges() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)

        var node1 = ThoughtNode(canvasId: canvas.id!, text: "A", x: 0, y: 0)
        var node2 = ThoughtNode(canvasId: canvas.id!, text: "B", x: 100, y: 0)
        try store.saveNode(&node1)
        try store.saveNode(&node2)

        var edge = Edge(canvasId: canvas.id!, sourceNodeId: node1.id!, targetNodeId: node2.id!)
        try store.saveEdge(&edge)
        XCTAssertEqual(try store.fetchEdges(canvasId: canvas.id!).count, 1)

        try store.deleteNode(id: node1.id!)
        XCTAssertEqual(try store.fetchEdges(canvasId: canvas.id!).count, 0)
    }

    func testSearchNodes() throws {
        var canvas = ThoughtCanvas(name: "Test")
        try store.saveCanvas(&canvas)

        var n1 = ThoughtNode(canvasId: canvas.id!, text: "Build the app", x: 0, y: 0)
        var n2 = ThoughtNode(canvasId: canvas.id!, text: "Design the UI", x: 100, y: 0)
        var n3 = ThoughtNode(canvasId: canvas.id!, text: "Ship it", x: 200, y: 0)
        try store.saveNode(&n1)
        try store.saveNode(&n2)
        try store.saveNode(&n3)

        let results = try store.searchNodes(query: "the")
        XCTAssertEqual(results.count, 2)
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `xcodebuild test -scheme gzgz -destination 'platform=macOS'`
Expected: FAIL

- [ ] **Step 4: Implement AppDatabase**

Create `gzgz/Database/Database.swift`:

```swift
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
        let writer = try DatabaseQueue(configuration: .init())
        return try AppDatabase(writer)
    }

    static func onDisk() throws -> AppDatabase {
        let url = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("gzgz", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let dbPath = url.appendingPathComponent("gzgz.sqlite").path
        let writer = try DatabaseQueue(path: dbPath)
        return try AppDatabase(writer)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "canvases") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull().defaults(to: "Untitled")
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: "thought_nodes") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("canvas", inTable: "canvases").notNull()
                    .indexed()
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
                t.belongsTo("canvas", inTable: "canvases").notNull()
                    .indexed()
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
```

- [ ] **Step 5: Implement Store**

Create `gzgz/Database/Store.swift`:

```swift
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
        try database.reader.read { db in
            try ThoughtNode
                .filter(Column("text").like("%\(query)%"))
                .fetchAll(db)
        }
    }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `xcodebuild test -scheme gzgz -destination 'platform=macOS'`
Expected: ALL PASS

- [ ] **Step 7: Commit**

```bash
git add gzgz/Database/ gzgzTests/Database/ && git commit -m "feat: add SQLite database layer with GRDB migrations and Store"
```

---

## Chunk 2: Sketch Rendering + Canvas Views

### Task 5: Sketch Renderer (Excalidraw-Style)

**Files:**

- Create: `gzgz/Theme/SketchRenderer.swift`

- [ ] **Step 1: Implement sketch rendering utilities**

Create `gzgz/Theme/SketchRenderer.swift`:

```swift
import SwiftUI

enum SketchRenderer {
    /// Seed-based random for deterministic wobble per shape
    static func wobble(seed: Int, index: Int, magnitude: Double = 2.0) -> Double {
        let hash = abs(seed &* 31 &+ index)
        let normalized = Double(hash % 1000) / 1000.0
        return (normalized - 0.5) * magnitude * 2
    }

    /// Create a sketchy rounded rectangle path with wobbly edges
    static func sketchyRect(
        in rect: CGRect,
        seed: Int,
        cornerRadius: CGFloat = 8,
        wobbleMagnitude: Double = 1.5
    ) -> Path {
        var path = Path()
        let segments = 20
        let w = rect.width
        let h = rect.height

        // Top edge
        for i in 0...segments {
            let t = Double(i) / Double(segments)
            let x = rect.minX + w * t
            let y = rect.minY + wobble(seed: seed, index: i, magnitude: wobbleMagnitude)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        // Right edge
        for i in 0...segments {
            let t = Double(i) / Double(segments)
            let x = rect.maxX + wobble(seed: seed, index: segments + i, magnitude: wobbleMagnitude)
            let y = rect.minY + h * t
            path.addLine(to: CGPoint(x: x, y: y))
        }
        // Bottom edge
        for i in 0...segments {
            let t = 1.0 - Double(i) / Double(segments)
            let x = rect.minX + w * t
            let y = rect.maxY + wobble(seed: seed, index: 2 * segments + i, magnitude: wobbleMagnitude)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        // Left edge
        for i in 0...segments {
            let t = 1.0 - Double(i) / Double(segments)
            let x = rect.minX + wobble(seed: seed, index: 3 * segments + i, magnitude: wobbleMagnitude)
            let y = rect.minY + h * t
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.closeSubpath()
        return path
    }

    /// Create a sketchy line path between two points
    static func sketchyLine(
        from start: CGPoint,
        to end: CGPoint,
        seed: Int,
        wobbleMagnitude: Double = 2.0
    ) -> Path {
        var path = Path()
        let segments = 16
        path.move(to: start)

        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        let nx = -dy / length  // normal x
        let ny = dx / length   // normal y

        for i in 1...segments {
            let t = Double(i) / Double(segments)
            let baseX = start.x + dx * t
            let baseY = start.y + dy * t
            let w = wobble(seed: seed, index: i, magnitude: wobbleMagnitude)
            let x = baseX + nx * w
            let y = baseY + ny * w
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }

    /// Arrowhead at end of a line
    static func arrowhead(at point: CGPoint, angle: Double, size: CGFloat = 12) -> Path {
        var path = Path()
        let left = CGPoint(
            x: point.x - size * cos(angle - .pi / 6),
            y: point.y - size * sin(angle - .pi / 6)
        )
        let right = CGPoint(
            x: point.x - size * cos(angle + .pi / 6),
            y: point.y - size * sin(angle + .pi / 6)
        )
        path.move(to: left)
        path.addLine(to: point)
        path.addLine(to: right)
        return path
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add gzgz/Theme/SketchRenderer.swift && git commit -m "feat: add Excalidraw-style sketch rendering engine"
```

---

### Task 6: Infinite Canvas Container

**Files:**

- Create: `gzgz/Views/Canvas/InfiniteCanvas.swift`

- [ ] **Step 1: Implement infinite pan/zoom canvas**

Create `gzgz/Views/Canvas/InfiniteCanvas.swift`:

```swift
import SwiftUI

struct InfiniteCanvas<Content: View>: View {
    @State private var zoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero
    @State private var lastPan: CGSize = .zero

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            content()
                .scaleEffect(zoom)
                .offset(x: pan.width, y: pan.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gzCanvasBackground)
                .clipped()
                .gesture(dragGesture)
                .gesture(magnifyGesture)
                .onTapGesture(count: 2) { location in
                    // Reset zoom/pan on double-tap with no node
                }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                pan = CGSize(
                    width: lastPan.width + value.translation.width,
                    height: lastPan.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastPan = pan
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = max(0.1, min(5.0, value.magnification))
            }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add gzgz/Views/Canvas/InfiniteCanvas.swift && git commit -m "feat: add infinite pan/zoom canvas container"
```

---

### Task 7: Node View

**Files:**

- Create: `gzgz/Views/Canvas/NodeView.swift`

- [ ] **Step 1: Implement sketchy node view**

Create `gzgz/Views/Canvas/NodeView.swift`:

```swift
import SwiftUI

struct NodeView: View {
    let node: ThoughtNode
    let isSelected: Bool
    let isSearchHighlighted: Bool
    let onSelect: () -> Void
    let onMove: (CGSize) -> Void
    let onEditText: (String) -> Void

    @State private var isEditing = false
    @State private var editText: String = ""
    @State private var dragOffset: CGSize = .zero

    private var seed: Int { Int(node.id ?? 0) }

    var body: some View {
        ZStack {
            // Sketchy rectangle background
            SketchRenderer.sketchyRect(
                in: CGRect(x: 0, y: 0, width: node.width, height: node.height),
                seed: seed
            )
            .fill(isSearchHighlighted ? Color.gzSearchHighlight : Color.gzNodeFill)

            SketchRenderer.sketchyRect(
                in: CGRect(x: 0, y: 0, width: node.width, height: node.height),
                seed: seed
            )
            .stroke(
                isSelected ? Color.gzPrimary : Color.gzNodeStroke,
                lineWidth: isSelected ? 2.5 : 1.5
            )

            // Text content
            if isEditing {
                TextField("", text: $editText, onCommit: {
                    onEditText(editText)
                    isEditing = false
                })
                .textFieldStyle(.plain)
                .font(GZFont.node())
                .foregroundColor(.gzText)
                .padding(12)
                .frame(width: node.width, height: node.height)
            } else {
                Text(node.text.isEmpty ? "..." : node.text)
                    .font(GZFont.node())
                    .foregroundColor(node.text.isEmpty ? .gzTextSecondary : .gzText)
                    .lineLimit(3)
                    .padding(12)
                    .frame(width: node.width, height: node.height, alignment: .topLeading)
            }
        }
        .frame(width: node.width, height: node.height)
        .position(x: node.x + node.width / 2 + dragOffset.width,
                  y: node.y + node.height / 2 + dragOffset.height)
        .onTapGesture {
            onSelect()
        }
        .onTapGesture(count: 2) {
            editText = node.text
            isEditing = true
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    onMove(value.translation)
                    dragOffset = .zero
                }
        )
        .shadow(color: Color.gzPrimary.opacity(isSelected ? 0.2 : 0), radius: 8)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add gzgz/Views/Canvas/NodeView.swift && git commit -m "feat: add sketchy NodeView with edit, select, and drag"
```

---

### Task 8: Edge Renderer

**Files:**

- Create: `gzgz/Views/Canvas/EdgeRenderer.swift`

- [ ] **Step 1: Implement sketchy edge rendering**

Create `gzgz/Views/Canvas/EdgeRenderer.swift`:

```swift
import SwiftUI

struct EdgeRenderer: View {
    let edge: Edge
    let sourceNode: ThoughtNode
    let targetNode: ThoughtNode
    let isSelected: Bool
    let onSelect: () -> Void

    private var seed: Int { Int(edge.id ?? 0) &+ 1000 }

    private var sourceCenter: CGPoint {
        CGPoint(x: sourceNode.x + sourceNode.width / 2,
                y: sourceNode.y + sourceNode.height / 2)
    }

    private var targetCenter: CGPoint {
        CGPoint(x: targetNode.x + targetNode.width / 2,
                y: targetNode.y + targetNode.height / 2)
    }

    /// Clip line to node border instead of center
    private var edgePoints: (start: CGPoint, end: CGPoint) {
        let start = clipToRect(
            from: sourceCenter, to: targetCenter,
            rect: CGRect(x: sourceNode.x, y: sourceNode.y,
                         width: sourceNode.width, height: sourceNode.height)
        )
        let end = clipToRect(
            from: targetCenter, to: sourceCenter,
            rect: CGRect(x: targetNode.x, y: targetNode.y,
                         width: targetNode.width, height: targetNode.height)
        )
        return (start, end)
    }

    var body: some View {
        let points = edgePoints
        let angle = atan2(points.end.y - points.start.y, points.end.x - points.start.x)

        ZStack {
            // Sketchy line
            SketchRenderer.sketchyLine(from: points.start, to: points.end, seed: seed)
                .stroke(
                    isSelected ? Color.gzPrimary : Color.gzEdgeStroke,
                    lineWidth: isSelected ? 2.5 : 1.5
                )

            // Arrowhead
            SketchRenderer.arrowhead(at: points.end, angle: angle)
                .stroke(
                    isSelected ? Color.gzPrimary : Color.gzEdgeStroke,
                    lineWidth: isSelected ? 2.5 : 1.5
                )

            // Label
            if let label = edge.label, !label.isEmpty {
                let mid = CGPoint(
                    x: (points.start.x + points.end.x) / 2,
                    y: (points.start.y + points.end.y) / 2 - 12
                )
                Text(label)
                    .font(GZFont.label())
                    .foregroundColor(.gzTextSecondary)
                    .position(mid)
            }
        }
        .contentShape(
            SketchRenderer.sketchyLine(from: points.start, to: points.end, seed: seed)
                .stroke(lineWidth: 12)
        )
        .onTapGesture { onSelect() }
    }

    private func clipToRect(from: CGPoint, to: CGPoint, rect: CGRect) -> CGPoint {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let cx = from.x
        let cy = from.y

        var tMin: CGFloat = 1.0

        if dx != 0 {
            let tLeft = (rect.minX - cx) / dx
            let tRight = (rect.maxX - cx) / dx
            for t in [tLeft, tRight] where t > 0 && t < tMin {
                let y = cy + t * dy
                if y >= rect.minY && y <= rect.maxY { tMin = t }
            }
        }
        if dy != 0 {
            let tTop = (rect.minY - cy) / dy
            let tBottom = (rect.maxY - cy) / dy
            for t in [tTop, tBottom] where t > 0 && t < tMin {
                let x = cx + t * dx
                if x >= rect.minX && x <= rect.maxX { tMin = t }
            }
        }

        return CGPoint(x: cx + tMin * dx, y: cy + tMin * dy)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add gzgz/Views/Canvas/EdgeRenderer.swift && git commit -m "feat: add sketchy edge rendering with arrowheads and labels"
```

---

## Chunk 3: Canvas ViewModel + Main Canvas View

### Task 9: CanvasViewModel

**Files:**

- Create: `gzgz/ViewModels/CanvasViewModel.swift`
- Create: `gzgzTests/ViewModels/CanvasViewModelTests.swift`

- [ ] **Step 1: Write CanvasViewModel tests**

Create `gzgzTests/ViewModels/CanvasViewModelTests.swift`:

```swift
import XCTest
@testable import gzgz

final class CanvasViewModelTests: XCTestCase {
    var vm: CanvasViewModel!

    override func setUp() async throws {
        let store = try Store(database: .inMemory())
        vm = CanvasViewModel(store: store)
        try vm.loadOrCreateDefaultCanvas()
    }

    func testCreateNode() throws {
        try vm.createNode(at: CGPoint(x: 100, y: 200))
        XCTAssertEqual(vm.nodes.count, 1)
        XCTAssertEqual(vm.nodes.first?.x, 100)
        XCTAssertEqual(vm.nodes.first?.y, 200)
    }

    func testUpdateNodeText() throws {
        try vm.createNode(at: CGPoint(x: 0, y: 0))
        let node = vm.nodes.first!
        try vm.updateNodeText(id: node.id!, text: "Hello")
        XCTAssertEqual(vm.nodes.first?.text, "Hello")
    }

    func testMoveNode() throws {
        try vm.createNode(at: CGPoint(x: 100, y: 100))
        let node = vm.nodes.first!
        try vm.moveNode(id: node.id!, delta: CGSize(width: 50, height: -30))
        XCTAssertEqual(vm.nodes.first?.x, 150)
        XCTAssertEqual(vm.nodes.first?.y, 70)
    }

    func testDeleteNode() throws {
        try vm.createNode(at: CGPoint(x: 0, y: 0))
        let node = vm.nodes.first!
        try vm.deleteNode(id: node.id!)
        XCTAssertTrue(vm.nodes.isEmpty)
    }

    func testCreateEdge() throws {
        try vm.createNode(at: CGPoint(x: 0, y: 0))
        try vm.createNode(at: CGPoint(x: 200, y: 200))
        let n1 = vm.nodes[0]
        let n2 = vm.nodes[1]
        try vm.createEdge(sourceId: n1.id!, targetId: n2.id!)
        XCTAssertEqual(vm.edges.count, 1)
    }

    func testDeleteNodeRemovesEdges() throws {
        try vm.createNode(at: CGPoint(x: 0, y: 0))
        try vm.createNode(at: CGPoint(x: 200, y: 200))
        let n1 = vm.nodes[0]
        let n2 = vm.nodes[1]
        try vm.createEdge(sourceId: n1.id!, targetId: n2.id!)
        try vm.deleteNode(id: n1.id!)
        XCTAssertTrue(vm.edges.isEmpty)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme gzgz -destination 'platform=macOS'`
Expected: FAIL

- [ ] **Step 3: Implement CanvasViewModel**

Create `gzgz/ViewModels/CanvasViewModel.swift`:

```swift
import SwiftUI

@Observable
final class CanvasViewModel {
    private let store: Store

    var nodes: [ThoughtNode] = []
    var edges: [Edge] = []
    var canvases: [ThoughtCanvas] = []
    var currentCanvasId: Int64?
    var selectedNodeId: Int64?
    var selectedEdgeId: Int64?

    // Connection drawing state
    var isDrawingEdge = false
    var edgeSourceId: Int64?
    var edgeDragPoint: CGPoint?

    init(store: Store) {
        self.store = store
    }

    func loadOrCreateDefaultCanvas() throws {
        canvases = try store.fetchCanvases()
        if canvases.isEmpty {
            var canvas = ThoughtCanvas(name: "Untitled")
            try store.saveCanvas(&canvas)
            canvases = [canvas]
        }
        currentCanvasId = canvases.first?.id
        try reload()
    }

    func reload() throws {
        guard let canvasId = currentCanvasId else { return }
        nodes = try store.fetchNodes(canvasId: canvasId)
        edges = try store.fetchEdges(canvasId: canvasId)
    }

    // MARK: - Nodes

    func createNode(at point: CGPoint) throws {
        guard let canvasId = currentCanvasId else { return }
        var node = ThoughtNode(
            canvasId: canvasId,
            text: "",
            x: point.x - 80,
            y: point.y - 30
        )
        try store.saveNode(&node)
        nodes.append(node)
        selectedNodeId = node.id
    }

    func updateNodeText(id: Int64, text: String) throws {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[index].text = text
        nodes[index].updatedAt = Date()
        try store.saveNode(&nodes[index])
    }

    func moveNode(id: Int64, delta: CGSize) throws {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[index].x += delta.width
        nodes[index].y += delta.height
        nodes[index].updatedAt = Date()
        try store.saveNode(&nodes[index])
    }

    func deleteNode(id: Int64) throws {
        try store.deleteNode(id: id)
        nodes.removeAll { $0.id == id }
        edges.removeAll { $0.sourceNodeId == id || $0.targetNodeId == id }
        if selectedNodeId == id { selectedNodeId = nil }
    }

    // MARK: - Edges

    func createEdge(sourceId: Int64, targetId: Int64, type: String = "related", label: String? = nil) throws {
        guard let canvasId = currentCanvasId else { return }
        guard sourceId != targetId else { return }
        // Prevent duplicate edges
        guard !edges.contains(where: { $0.sourceNodeId == sourceId && $0.targetNodeId == targetId }) else { return }

        var edge = Edge(
            canvasId: canvasId,
            sourceNodeId: sourceId,
            targetNodeId: targetId,
            relationshipType: type,
            label: label
        )
        try store.saveEdge(&edge)
        edges.append(edge)
    }

    func deleteEdge(id: Int64) throws {
        try store.deleteEdge(id: id)
        edges.removeAll { $0.id == id }
        if selectedEdgeId == id { selectedEdgeId = nil }
    }

    // MARK: - Selection

    func clearSelection() {
        selectedNodeId = nil
        selectedEdgeId = nil
    }

    func deleteSelected() throws {
        if let nodeId = selectedNodeId {
            try deleteNode(id: nodeId)
        } else if let edgeId = selectedEdgeId {
            try deleteEdge(id: edgeId)
        }
    }

    // MARK: - Canvas Management

    func createCanvas(name: String) throws {
        var canvas = ThoughtCanvas(name: name)
        try store.saveCanvas(&canvas)
        canvases.append(canvas)
        currentCanvasId = canvas.id
        try reload()
    }

    func switchCanvas(id: Int64) throws {
        currentCanvasId = id
        clearSelection()
        try reload()
    }

    func renameCanvas(id: Int64, name: String) throws {
        guard let index = canvases.firstIndex(where: { $0.id == id }) else { return }
        canvases[index].name = name
        canvases[index].updatedAt = Date()
        try store.saveCanvas(&canvases[index])
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme gzgz -destination 'platform=macOS'`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add gzgz/ViewModels/CanvasViewModel.swift gzgzTests/ViewModels/ && git commit -m "feat: add CanvasViewModel with node/edge CRUD and canvas management"
```

---

### Task 10: Canvas Content View (Main Assembly)

**Files:**

- Create: `gzgz/Views/Canvas/CanvasContentView.swift`
- Modify: `gzgz/App/ContentView.swift`
- Modify: `gzgz/App/gzgzApp.swift`

- [ ] **Step 1: Implement CanvasContentView**

Create `gzgz/Views/Canvas/CanvasContentView.swift`:

```swift
import SwiftUI

struct CanvasContentView: View {
    @Bindable var vm: CanvasViewModel
    @State private var zoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero
    @State private var lastPan: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background — tap to deselect or create node
                Color.gzCanvasBackground
                    .onTapGesture { location in
                        vm.clearSelection()
                    }
                    .onTapGesture(count: 2) { location in
                        let canvasPoint = screenToCanvas(location, in: geometry.size)
                        try? vm.createNode(at: canvasPoint)
                    }

                // Canvas content with transform
                ZStack {
                    // Edges
                    ForEach(vm.edges) { edge in
                        if let source = vm.nodes.first(where: { $0.id == edge.sourceNodeId }),
                           let target = vm.nodes.first(where: { $0.id == edge.targetNodeId }) {
                            EdgeRenderer(
                                edge: edge,
                                sourceNode: source,
                                targetNode: target,
                                isSelected: vm.selectedEdgeId == edge.id,
                                onSelect: {
                                    vm.selectedNodeId = nil
                                    vm.selectedEdgeId = edge.id
                                }
                            )
                        }
                    }

                    // Nodes
                    ForEach(vm.nodes) { node in
                        NodeView(
                            node: node,
                            isSelected: vm.selectedNodeId == node.id,
                            isSearchHighlighted: false,
                            onSelect: {
                                vm.selectedEdgeId = nil
                                vm.selectedNodeId = node.id
                            },
                            onMove: { delta in
                                try? vm.moveNode(id: node.id!, delta: delta)
                            },
                            onEditText: { text in
                                try? vm.updateNodeText(id: node.id!, text: text)
                            }
                        )
                    }
                }
                .scaleEffect(zoom)
                .offset(x: pan.width, y: pan.height)
            }
            .gesture(panGesture)
            .gesture(zoomGesture)
            .onKeyPress(.delete) {
                try? vm.deleteSelected()
                return .handled
            }
            .onKeyPress(.deleteForward) {
                try? vm.deleteSelected()
                return .handled
            }
        }
    }

    private func screenToCanvas(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: (point.x - size.width / 2 - pan.width) / zoom + size.width / 2,
            y: (point.y - size.height / 2 - pan.height) / zoom + size.height / 2
        )
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .modifiers(.command)
            .onChanged { value in
                pan = CGSize(
                    width: lastPan.width + value.translation.width,
                    height: lastPan.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastPan = pan
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = max(0.1, min(5.0, value.magnification))
            }
    }
}
```

- [ ] **Step 2: Update ContentView as root layout**

Replace `gzgz/App/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @State var vm: CanvasViewModel

    var body: some View {
        CanvasContentView(vm: vm)
            .frame(minWidth: 800, minHeight: 600)
            .task {
                try? vm.loadOrCreateDefaultCanvas()
            }
    }
}
```

- [ ] **Step 3: Update gzgzApp with Store initialization**

Replace `gzgz/App/gzgzApp.swift`:

```swift
import SwiftUI

@main
struct gzgzApp: App {
    private let store: Store

    init() {
        do {
            let database = try AppDatabase.onDisk()
            store = Store(database: database)
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(vm: CanvasViewModel(store: store))
        }
        .windowStyle(.automatic)
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -scheme gzgz -destination 'platform=macOS' build`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add gzgz/Views/Canvas/CanvasContentView.swift gzgz/App/ && git commit -m "feat: assemble main canvas view with nodes, edges, pan/zoom"
```

---

## Chunk 4: Search, History, Sidebar

### Task 11: Search Overlay (Cmd+K)

**Files:**

- Create: `gzgz/ViewModels/SearchViewModel.swift`
- Create: `gzgz/Views/Search/SearchOverlay.swift`
- Create: `gzgzTests/ViewModels/SearchViewModelTests.swift`

- [ ] **Step 1: Write SearchViewModel tests**

Create `gzgzTests/ViewModels/SearchViewModelTests.swift`:

```swift
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
```

- [ ] **Step 2: Implement SearchViewModel**

Create `gzgz/ViewModels/SearchViewModel.swift`:

```swift
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
```

- [ ] **Step 3: Implement SearchOverlay view**

Create `gzgz/Views/Search/SearchOverlay.swift`:

```swift
import SwiftUI

struct SearchOverlay: View {
    @Bindable var vm: SearchViewModel
    let onNavigateToNode: (ThoughtNode) -> Void

    var body: some View {
        if vm.isVisible {
            VStack(spacing: 0) {
                // Search input
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gzTextSecondary)
                    TextField("Search thoughts...", text: $vm.query)
                        .textFieldStyle(.plain)
                        .font(GZFont.search())
                        .foregroundColor(.gzText)
                        .onChange(of: vm.query) { _, newValue in
                            try? vm.search(query: newValue)
                        }
                        .onKeyPress(.downArrow) {
                            vm.selectNext()
                            return .handled
                        }
                        .onKeyPress(.upArrow) {
                            vm.selectPrevious()
                            return .handled
                        }
                        .onKeyPress(.return) {
                            if let node = vm.selectedResult {
                                onNavigateToNode(node)
                                vm.toggle()
                            }
                            return .handled
                        }
                        .onKeyPress(.escape) {
                            vm.toggle()
                            return .handled
                        }
                }
                .padding(12)
                .background(Color.gzNodeFill)

                Divider()

                // Results
                if !vm.results.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(vm.results.enumerated()), id: \.element.id) { index, node in
                                HStack {
                                    Text(node.text.isEmpty ? "(empty)" : node.text)
                                        .font(GZFont.node())
                                        .foregroundColor(.gzText)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    index == vm.selectedResultIndex
                                        ? Color.gzSelection
                                        : Color.clear
                                )
                                .onTapGesture {
                                    onNavigateToNode(node)
                                    vm.toggle()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                } else if !vm.query.isEmpty {
                    Text("No results")
                        .font(GZFont.label())
                        .foregroundColor(.gzTextSecondary)
                        .padding(12)
                }
            }
            .frame(width: 400)
            .background(Color.gzBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        }
    }
}
```

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -scheme gzgz -destination 'platform=macOS'`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add gzgz/ViewModels/SearchViewModel.swift gzgz/Views/Search/ gzgzTests/ViewModels/SearchViewModelTests.swift && git commit -m "feat: add Cmd+K search with overlay and keyboard navigation"
```

---

### Task 12: History Manager (Undo/Redo)

**Files:**

- Create: `gzgz/ViewModels/HistoryManager.swift`
- Create: `gzgz/Views/History/HistoryPanel.swift`
- Create: `gzgzTests/ViewModels/HistoryManagerTests.swift`

- [ ] **Step 1: Write HistoryManager tests**

Create `gzgzTests/ViewModels/HistoryManagerTests.swift`:

```swift
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
        XCTAssertEqual(actions.count, 2) // undo 2 actions to get to index 0
    }
}
```

- [ ] **Step 2: Implement HistoryManager**

Create `gzgz/ViewModels/HistoryManager.swift`:

```swift
import Foundation

enum HistoryAction: Identifiable {
    case createNode(id: Int64, canvasId: Int64, text: String, x: Double, y: Double)
    case deleteNode(id: Int64, canvasId: Int64, text: String, x: Double, y: Double, width: Double, height: Double)
    case moveNode(id: Int64, fromX: Double, fromY: Double, toX: Double, toY: Double)
    case updateText(id: Int64, oldText: String, newText: String)
    case createEdge(id: Int64, canvasId: Int64, sourceId: Int64, targetId: Int64, type: String, label: String?)
    case deleteEdge(id: Int64, canvasId: Int64, sourceId: Int64, targetId: Int64, type: String, label: String?)

    var id: UUID { UUID() }

    var displayName: String {
        switch self {
        case .createNode: return "Create node"
        case .deleteNode: return "Delete node"
        case .moveNode: return "Move node"
        case .updateText(_, _, let newText): return "Edit: \"\(newText.prefix(20))\""
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
            // Undo forward to target
            while currentIndex > index {
                if let action = undo() {
                    actions.append(action)
                }
            }
        } else if index > currentIndex {
            // Redo forward to target
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
```

- [ ] **Step 3: Implement HistoryPanel view**

Create `gzgz/Views/History/HistoryPanel.swift`:

```swift
import SwiftUI

struct HistoryPanel: View {
    let history: HistoryManager
    let onJumpTo: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("History")
                .font(GZFont.nodeTitle())
                .foregroundColor(.gzText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            if history.entries.isEmpty {
                Text("No actions yet")
                    .font(GZFont.label())
                    .foregroundColor(.gzTextSecondary)
                    .padding(12)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(history.entries.enumerated()), id: \.offset) { index, entry in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(index <= history.currentIndex ? Color.gzPrimary : Color.gzTextSecondary.opacity(0.3))
                                    .frame(width: 6, height: 6)

                                Text(entry.displayName)
                                    .font(GZFont.label())
                                    .foregroundColor(
                                        index <= history.currentIndex ? .gzText : .gzTextSecondary
                                    )
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                index == history.currentIndex
                                    ? Color.gzSelection
                                    : Color.clear
                            )
                            .onTapGesture {
                                onJumpTo(index)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 200)
        .background(Color.gzBackground)
    }
}
```

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -scheme gzgz -destination 'platform=macOS'`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add gzgz/ViewModels/HistoryManager.swift gzgz/Views/History/ gzgzTests/ViewModels/HistoryManagerTests.swift && git commit -m "feat: add Photoshop-style undo/redo history with panel"
```

---

### Task 13: Canvas Sidebar

**Files:**

- Create: `gzgz/Views/Sidebar/CanvasSidebar.swift`

- [ ] **Step 1: Implement canvas list sidebar**

Create `gzgz/Views/Sidebar/CanvasSidebar.swift`:

```swift
import SwiftUI

struct CanvasSidebar: View {
    @Bindable var vm: CanvasViewModel
    @State private var isAddingCanvas = false
    @State private var newCanvasName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Canvases")
                    .font(GZFont.nodeTitle())
                    .foregroundColor(.gzText)
                Spacer()
                Button(action: { isAddingCanvas = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.gzPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Canvas list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(vm.canvases) { canvas in
                        HStack {
                            Text(canvas.name)
                                .font(GZFont.node())
                                .foregroundColor(.gzText)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            vm.currentCanvasId == canvas.id
                                ? Color.gzSelection
                                : Color.clear
                        )
                        .onTapGesture {
                            try? vm.switchCanvas(id: canvas.id!)
                        }
                    }
                }
            }

            // New canvas input
            if isAddingCanvas {
                HStack {
                    TextField("Canvas name", text: $newCanvasName, onCommit: {
                        let name = newCanvasName.isEmpty ? "Untitled" : newCanvasName
                        try? vm.createCanvas(name: name)
                        newCanvasName = ""
                        isAddingCanvas = false
                    })
                    .textFieldStyle(.plain)
                    .font(GZFont.node())
                    .padding(8)
                }
                .padding(.horizontal, 12)
            }
        }
        .frame(width: 180)
        .background(Color.gzBackground)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add gzgz/Views/Sidebar/CanvasSidebar.swift && git commit -m "feat: add canvas list sidebar with create/switch"
```

---

### Task 14: Wire Everything Together in ContentView

**Files:**

- Modify: `gzgz/App/ContentView.swift`

- [ ] **Step 1: Update ContentView with sidebar, search, history, and keyboard shortcuts**

Replace `gzgz/App/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @State var vm: CanvasViewModel
    @State private var searchVM: SearchViewModel
    @State private var history = HistoryManager()
    @State private var showHistory = false

    init(vm: CanvasViewModel, store: Store) {
        self._vm = State(initialValue: vm)
        self._searchVM = State(initialValue: SearchViewModel(store: store))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            CanvasSidebar(vm: vm)
            Divider()

            // Main canvas area
            ZStack {
                CanvasContentView(
                    vm: vm,
                    highlightedNodeIds: searchVM.highlightedNodeIds
                )

                // Search overlay
                VStack {
                    SearchOverlay(vm: searchVM) { node in
                        vm.selectedNodeId = node.id
                    }
                    .padding(.top, 60)
                    Spacer()
                }

                // History panel toggle
                HStack {
                    Spacer()
                    if showHistory {
                        HistoryPanel(history: history) { index in
                            let actions = history.jumpTo(index: index)
                            for action in actions {
                                applyHistoryAction(action)
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.gzBackground)
        .task {
            try? vm.loadOrCreateDefaultCanvas()
        }
        // Keyboard shortcuts
        .onKeyPress(KeyEquivalent("k"), modifiers: .command) {
            searchVM.toggle()
            return .handled
        }
        .onKeyPress(KeyEquivalent("z"), modifiers: .command) {
            if let action = history.undo() {
                applyHistoryAction(action)
            }
            return .handled
        }
        .onKeyPress(KeyEquivalent("z"), modifiers: [.command, .shift]) {
            if let action = history.redo() {
                applyHistoryAction(action)
            }
            return .handled
        }
        .onKeyPress(KeyEquivalent("y"), modifiers: .command) {
            showHistory.toggle()
            return .handled
        }
    }

    private func applyHistoryAction(_ action: HistoryAction) {
        switch action {
        case .createNode(let id, let canvasId, let text, let x, let y):
            var node = ThoughtNode(id: id, canvasId: canvasId, text: text, x: x, y: y)
            try? vm.store.saveNode(&node)
            try? vm.reload()
        case .deleteNode(let id, _, _, _, _, _, _):
            try? vm.deleteNode(id: id)
        case .moveNode(let id, _, _, let toX, let toY):
            if let index = vm.nodes.firstIndex(where: { $0.id == id }) {
                let dx = toX - vm.nodes[index].x
                let dy = toY - vm.nodes[index].y
                try? vm.moveNode(id: id, delta: CGSize(width: dx, height: dy))
            }
        case .updateText(let id, _, let newText):
            try? vm.updateNodeText(id: id, text: newText)
        case .createEdge(_, _, let sourceId, let targetId, let type, let label):
            try? vm.createEdge(sourceId: sourceId, targetId: targetId, type: type, label: label)
        case .deleteEdge(let id, _, _, _, _, _):
            try? vm.deleteEdge(id: id)
        }
    }
}
```

- [ ] **Step 2: Update CanvasContentView to accept highlightedNodeIds**

Add `highlightedNodeIds: Set<Int64> = []` parameter to `CanvasContentView` and pass it to `NodeView.isSearchHighlighted`.

- [ ] **Step 3: Update gzgzApp to pass store**

Replace `gzgz/App/gzgzApp.swift`:

```swift
import SwiftUI

@main
struct gzgzApp: App {
    private let store: Store

    init() {
        do {
            let database = try AppDatabase.onDisk()
            store = Store(database: database)
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(vm: CanvasViewModel(store: store), store: store)
        }
        .windowStyle(.automatic)
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -scheme gzgz -destination 'platform=macOS' build`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Run all tests**

Run: `xcodebuild test -scheme gzgz -destination 'platform=macOS'`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add gzgz/ && git commit -m "feat: wire up sidebar, search, history, and keyboard shortcuts"
```

---

## Chunk 5: Polish & Alpha Release

### Task 15: Remove InfiniteCanvas (unused), Final Cleanup

- [ ] **Step 1: Delete `gzgz/Views/Canvas/InfiniteCanvas.swift`** (pan/zoom is built into CanvasContentView)

- [ ] **Step 2: Verify build**

Run: `xcodebuild -scheme gzgz -destination 'platform=macOS' build`

- [ ] **Step 3: Verify all tests pass**

Run: `xcodebuild test -scheme gzgz -destination 'platform=macOS'`

- [ ] **Step 4: Commit and tag alpha**

```bash
git add -A && git commit -m "chore: cleanup unused files, alpha v0.1.0 ready"
git tag v0.1.0-alpha
git push && git push --tags
```

---

## Summary

| Task | What | Files |
|------|------|-------|
| 1 | Project scaffold + XcodeGen | project.yml, App/ |
| 2 | Theme colors + fonts | Theme/ |
| 3 | Data models (Node, Edge, Canvas) | Models/, Tests |
| 4 | Database + Store (GRDB) | Database/, Tests |
| 5 | Sketch renderer (Excalidraw) | Theme/SketchRenderer |
| 6 | Infinite canvas container | Views/Canvas/ |
| 7 | Node view | Views/Canvas/ |
| 8 | Edge renderer | Views/Canvas/ |
| 9 | Canvas ViewModel | ViewModels/, Tests |
| 10 | Canvas content view assembly | Views/Canvas/, App/ |
| 11 | Search (Cmd+K) | ViewModels/, Views/Search/, Tests |
| 12 | Undo/redo history | ViewModels/, Views/History/, Tests |
| 13 | Canvas sidebar | Views/Sidebar/ |
| 14 | Wire everything together | App/ |
| 15 | Cleanup + alpha tag | cleanup |
