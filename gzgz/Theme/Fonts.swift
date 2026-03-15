import SwiftUI

/// Font configuration mimicking Excalidraw's handwritten style.
/// Uses system fonts with design hints that approximate the hand-drawn aesthetic.
/// TODO: Bundle Virgil or similar handwritten font for true Excalidraw feel.
enum GZFont {
    /// Primary text in nodes — handwritten feel
    static func hand(_ size: CGFloat = 16) -> Font {
        // .serif with italic gives a more organic, handwritten feel than .rounded
        .system(size: size, design: .serif)
    }

    /// Node title / labels
    static func handBold(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }

    /// UI chrome text (sidebar, panels) — clean sans-serif
    static func ui(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    /// UI chrome bold
    static func uiBold(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    /// Search input
    static func search(_ size: CGFloat = 16) -> Font {
        .system(size: size, design: .default)
    }

    /// Edge labels
    static func label(_ size: CGFloat = 12) -> Font {
        .system(size: size, design: .serif)
    }
}
