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
