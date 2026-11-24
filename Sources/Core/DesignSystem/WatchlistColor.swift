import SwiftUI

enum WatchlistColor {
    static let background = Color(hex: 0x08090B)
    static let backgroundElevated = Color(hex: 0x111318)
    static let surface = Color(hex: 0x171A20)
    static let surfaceElevated = Color(hex: 0x20242C)
    static let accent = Color(hex: 0xC6F36A)
    static let accentPressed = Color(hex: 0xA8D94A)
    static let primaryText = Color(hex: 0xF5F5F2)
    static let secondaryText = Color(hex: 0xA5A9B2)
    static let mutedText = Color(hex: 0x737985)
    static let warmHighlight = Color(hex: 0xD8C39A)
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
