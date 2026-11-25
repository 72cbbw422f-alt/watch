import Foundation
import SwiftData

@Model
final class PremiereReminder {
    @Attribute(.unique) var stableID: String
    var tmdbID: Int
    var mediaKind: String
    var title: String
    var premiereDate: Date
    var leadDays: Int
    var notificationID: String
    var dateCreated: Date

    init(item: MediaItem, premiereDate: Date, leadDays: Int) {
        stableID = item.stableID
        tmdbID = item.id
        mediaKind = item.kind.rawValue
        title = item.title
        self.premiereDate = premiereDate
        self.leadDays = leadDays
        notificationID = "premiere-\(item.stableID)"
        dateCreated = .now
    }

    var leadDescription: String {
        switch leadDays {
        case 7: "En vecka före"
        case 1: "Dagen före"
        default: "Samma dag"
        }
    }
}
