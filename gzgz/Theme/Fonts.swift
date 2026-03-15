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
