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
                .onAppear {
                    setupCaptureListener()
                }
        }
        .windowStyle(.automatic)
    }

    /// Listen for external capture requests via a file signal.
    /// Agent writes to /tmp/gzgz-capture-request, app captures and removes the signal.
    private func setupCaptureListener() {
        let signalPath = "/tmp/gzgz-capture-request"
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if FileManager.default.fileExists(atPath: signalPath) {
                try? FileManager.default.removeItem(atPath: signalPath)
                Task { @MainActor in
                    let _ = CanvasCapture.captureWindow()
                }
            }
        }
    }
}
