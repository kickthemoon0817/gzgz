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
