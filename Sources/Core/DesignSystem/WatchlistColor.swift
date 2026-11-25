import SwiftUI

enum WatchlistColor {
    // Restrained graphite palette with a warm, editorial amber accent.
    static let background = Color(hex: 0x0B0C0E)
    static let backgroundElevated = Color(hex: 0x121417)
    static let surface = Color(hex: 0x191C20)
    static let surfaceElevated = Color(hex: 0x24282D)
    static let accent = Color(hex: 0xD49A68)
    static let accentPressed = Color(hex: 0xB77A4A)
    static let primaryText = Color(hex: 0xF1EEE9)
    static let secondaryText = Color(hex: 0xB4B0AA)
    static let mutedText = Color(hex: 0x817D77)
    static let warmHighlight = Color(hex: 0xD8C8B7)
    static let hairline = Color.white.opacity(0.075)
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
