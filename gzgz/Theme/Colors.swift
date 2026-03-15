import SwiftUI

extension Color {
    // Russian Violet identity — used for branding accents, not as default stroke
    static let gzBrand = Color(hex: "#32174D")
    static let gzBrandLight = Color(hex: "#4A2570")

    // Excalidraw-inspired functional palette
    static let gzStroke = Color(hex: "#1e1e1e")           // Default stroke (near-black, like pencil)
    static let gzStrokeLight = Color(hex: "#1e1e1e").opacity(0.6)
    static let gzBackground = Color(hex: "#FFFFFF")        // Clean white canvas
    static let gzCanvasBackground = Color(hex: "#FFFFFF")
    static let gzNodeFill = Color(hex: "#FFFFFF")          // White node fill
    static let gzNodeStroke = Color(hex: "#1e1e1e")        // Pencil-dark stroke
    static let gzEdgeStroke = Color(hex: "#1e1e1e")        // Same pencil stroke for edges
    static let gzText = Color(hex: "#1e1e1e")
    static let gzTextSecondary = Color(hex: "#868e96")     // Muted gray
    static let gzSelection = Color(hex: "#6965db").opacity(0.15)  // Excalidraw selection blue-purple
    static let gzSelectionStroke = Color(hex: "#6965db")
    static let gzSearchHighlight = Color(hex: "#ffd700").opacity(0.35)
    static let gzDotGrid = Color(hex: "#e2e2e2")           // Subtle dot grid

    // Sidebar / UI chrome
    static let gzChrome = Color(hex: "#f8f9fa")
    static let gzChromeBorder = Color(hex: "#e9ecef")

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
