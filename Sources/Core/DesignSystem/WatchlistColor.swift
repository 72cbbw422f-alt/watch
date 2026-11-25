import SwiftUI

enum WatchlistColor {
    static let background = Color(hex: 0x080808)
    static let backgroundElevated = Color(hex: 0x111111)
    static let surface = Color(hex: 0x191919)
    static let surfaceElevated = Color(hex: 0x242424)
    static let accent = Color(hex: 0xF47721)
    static let accentPressed = Color(hex: 0xD96116)
    static let primaryText = Color(hex: 0xF4F1ED)
    static let secondaryText = Color(hex: 0xAAA6A1)
    static let mutedText = Color(hex: 0x77736F)
    static let warmHighlight = Color(hex: 0xD0C8BE)
    static let hairline = Color.white.opacity(0.09)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
