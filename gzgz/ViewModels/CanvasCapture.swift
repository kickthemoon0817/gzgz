import SwiftUI
import AppKit

/// Captures the app's canvas as a PNG image to a known path.
/// Designed to be called by AI agents via MCP/CLI to "see" the app.
enum CanvasCapture {

    /// Default output path for agent consumption
    static let defaultPath = "/tmp/gzgz-canvas.png"

    /// Capture the main window's content as PNG
    @MainActor
    static func captureWindow(to path: String = defaultPath) -> Bool {
        guard let window = NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) else {
            return false
        }

        guard let contentView = window.contentView else {
            return false
        }

        let bounds = contentView.bounds
        guard let bitmap = contentView.bitmapImageRepForCachingDisplay(in: bounds) else {
            return false
        }

        contentView.cacheDisplay(in: bounds, to: bitmap)

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            return false
        }

        let url = URL(fileURLWithPath: path)
        do {
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }

    /// Capture and return the image data directly (for future MCP use)
    @MainActor
    static func captureWindowData() -> Data? {
        guard let window = NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }),
              let contentView = window.contentView else {
            return nil
        }

        let bounds = contentView.bounds
        guard let bitmap = contentView.bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }

        contentView.cacheDisplay(in: bounds, to: bitmap)
        return bitmap.representation(using: .png, properties: [:])
    }
}
