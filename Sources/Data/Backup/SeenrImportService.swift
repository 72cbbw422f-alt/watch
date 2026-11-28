import Foundation
import SwiftData

struct SeenrImportPreview {
    let newTitles: Int
    let matchingTitles: Int
    let newEpisodeStates: Int
    let newEpisodeHistory: Int
    let newMovieHistory: Int
    let newImportedRatings: Int
    let skippedTitles: Int
    let warnings: [String]
}

@MainActor
enum SeenrImportService {
    static func preview(_ payload: SeenrImportPayload, in context: ModelContext) throws -> SeenrImportPreview {
        let library = try context.fetch(FetchDescriptor<LibraryEntry>())
        let progress = try context.fetch(FetchDescriptor<EpisodeProgress>())
        let episodeHistory = try context.fetch(FetchDescriptor<EpisodeWatchEvent>())
        let movieHistory = try context.fetch(FetchDescriptor<MovieWatchEvent>())
        let importedRatings = try context.fetch(FetchDescriptor<ImportedWorkRating>())
        let existingTitles = Set(library.map(\.stableID))
        let existingProgress = Set(progress.map(\.stableID))
        let existingEpisodeEvents = Set(episodeHistory.map(\.id))
        let existingMovieEvents = Set(movieHistory.map(\.id))
        let existingRatingIDs = Set(importedRatings.map(\.stableID))

        let incomingTitles = (payload.shows + payload.movies).filter { mappedStatus($0.status) != nil }
        let titleIDs = incomingTitles.map { "\($0.kind)-\($0.tmdbID)" }
        let episodes = episodeProgressCandidates(payload)
        let episodeEvents = episodeEventCandidates(payload)
        let movieEvents = movieEventCandidates(payload)

        return SeenrImportPreview(
            newTitles: Set(titleIDs).subtracting(existingTitles).count,
            matchingTitles: Set(titleIDs).intersection(existingTitles).count,
            newEpisodeStates: episodes.filter {
                !existingProgress.contains(EpisodeProgress.makeStableID(
                    seriesID: $0.seriesID, seasonNumber: $0.season, episodeNumber: $0.number
                ))
            }.count,
            newEpisodeHistory: episodeEvents.filter { !existingEpisodeEvents.contains($0.id) }.count,
            newMovieHistory: movieEvents.filter { !existingMovieEvents.contains($0.id) }.count,
            newImportedRatings: ratingCandidates(payload).filter { !existingRatingIDs.contains($0.stableID) }.count,
            skippedTitles: payload.shows.count + payload.movies.count - incomingTitles.count,
            warnings: payload.warnings + unknownStatusWarnings(payload) + incompleteWatchHistoryWarnings(payload)
        )
    }

    /// Additive and idempotent: existing library records and local-only records are untouched.
    static func merge(_ payload: SeenrImportPayload, into context: ModelContext) throws -> SeenrImportPreview {
        let summary = try preview(payload, in: context)
        try context.transaction {
            let library = try context.fetch(FetchDescriptor<LibraryEntry>())
            let progress = try context.fetch(FetchDescriptor<EpisodeProgress>())
            let episodeHistory = try context.fetch(FetchDescriptor<EpisodeWatchEvent>())
            let movieHistory = try context.fetch(FetchDescriptor<MovieWatchEvent>())
            let importedRatings = try context.fetch(FetchDescriptor<ImportedWorkRating>())
            var titleIDs = Set(library.map(\.stableID))
            var progressIDs = Set(progress.map(\.stableID))
            var episodeEventIDs = Set(episodeHistory.map(\.id))
            var movieEventIDs = Set(movieHistory.map(\.id))
            var ratingIDs = Set(importedRatings.map(\.stableID))

            for record in payload.shows + payload.movies {
                guard let status = mappedStatus(record.status) else { continue }
                let stableID = "\(record.kind)-\(record.tmdbID)"
                guard titleIDs.insert(stableID).inserted else { continue }
                let kind: MediaKind = record.kind == "television" ? .television : .movie
                let yearDate = record.year.map { String(format: "%04d-01-01", $0) }
                let item = MediaItem(
                    id: record.tmdbID, kind: kind, title: record.title,
                    overview: "", releaseDate: yearDate
                )
                let entry = LibraryEntry(item: item, status: status)
                entry.dateAdded = record.addedAt ?? .now
                entry.dateUpdated = record.completedAt ?? record.startedAt ?? record.addedAt ?? .now
                entry.isFavorite = record.favorite
                entry.personalRating = record.rating.flatMap { (1...10).contains($0) ? $0 : nil }
                entry.personalNotes = record.review ?? ""
                context.insert(entry)
            }

            for record in episodeProgressCandidates(payload) {
                let stableID = EpisodeProgress.makeStableID(
                    seriesID: record.seriesID, seasonNumber: record.season, episodeNumber: record.number
                )
                guard progressIDs.insert(stableID).inserted else { continue }
                let episode = TVEpisode(
                    id: record.episodeID,
                    name: record.title, overview: "",
                    episodeNumber: record.number, seasonNumber: record.season,
                    airDate: record.airDate, runtime: nil, stillPath: nil, voteAverage: 0
                )
                let state = EpisodeProgress(seriesID: record.seriesID, episode: episode, isWatched: true)
                state.watchedAt = record.watchedAt
                context.insert(state)
            }

            for record in episodeEventCandidates(payload) {
                guard episodeEventIDs.insert(record.id).inserted else { continue }
                context.insert(EpisodeWatchEvent(
                    id: record.id, seriesID: record.seriesID, episodeID: record.episodeID,
                    seasonNumber: record.season, episodeNumber: record.number,
                    episodeTitle: record.title, watchedAt: record.watchedAt,
                    source: "seenr-import"
                ))
            }

            for record in movieEventCandidates(payload) {
                guard movieEventIDs.insert(record.id).inserted else { continue }
                context.insert(MovieWatchEvent(
                    id: record.id, tmdbID: record.tmdbID, title: record.title,
                    posterPath: nil, watchedAt: record.watchedAt, source: "seenr-import"
                ))
            }
            for rating in ratingCandidates(payload) {
                guard ratingIDs.insert(rating.stableID).inserted else { continue }
                context.insert(ImportedWorkRating(
                    stableID: rating.stableID, kind: rating.kind, tmdbID: rating.tmdbID,
                    seriesID: rating.seriesID, seasonNumber: rating.season,
                    episodeNumber: rating.episode, title: rating.title, score: rating.score,
                    review: rating.review, isSpoiler: rating.isSpoiler, createdAt: rating.createdAt
                ))
            }

        }
        return summary
    }

    private struct RatingCandidate {
        let stableID: String
        let kind: String
        let tmdbID: Int
        let seriesID: Int?
        let season: Int?
        let episode: Int?
        let title: String
        let score: Double
        let review: String?
        let isSpoiler: Bool
        let createdAt: Date?
    }

    private static func ratingCandidates(_ payload: SeenrImportPayload) -> [RatingCandidate] {
        payload.ratings.filter { ["season", "episode"].contains($0.kind) && (0...10).contains($0.score) }
            .map { rating in
                let identity = "\(rating.kind)|\(rating.tmdbID)|\(rating.seriesID ?? 0)|\(rating.season ?? 0)|\(rating.episode ?? 0)|\(rating.createdAt?.timeIntervalSince1970 ?? 0)"
                return RatingCandidate(
                    stableID: identity, kind: rating.kind, tmdbID: rating.tmdbID,
                    seriesID: rating.seriesID, season: rating.season, episode: rating.episode,
                    title: rating.title, score: rating.score, review: rating.review,
                    isSpoiler: rating.isSpoiler, createdAt: rating.createdAt
                )
            }
    }

    private struct EpisodeProgressCandidate {
        let seriesID: Int
        let season: Int
        let number: Int
        let episodeID: Int
        let title: String
        let airDate: String?
        let watchedAt: Date?
    }

    private static func episodeProgressCandidates(_ payload: SeenrImportPayload) -> [EpisodeProgressCandidate] {
        var candidates: [String: EpisodeProgressCandidate] = [:]
        for episode in payload.episodes where episode.seriesID > 0 && episode.season >= 0 && episode.number > 0 {
            let key = EpisodeProgress.makeStableID(seriesID: episode.seriesID, seasonNumber: episode.season, episodeNumber: episode.number)
            candidates[key] = EpisodeProgressCandidate(
                seriesID: episode.seriesID, season: episode.season, number: episode.number,
                episodeID: episode.tmdbID ?? episode.number, title: episode.title,
                airDate: episode.airDate, watchedAt: episode.watchedAt ?? episode.dates.last
            )
        }
        for viewing in payload.viewings where viewing.kind == "episode" {
            guard let seriesID = viewing.seriesID, let season = viewing.season,
                  let number = viewing.episode, seriesID > 0, season >= 0, number > 0 else { continue }
            let key = EpisodeProgress.makeStableID(seriesID: seriesID, seasonNumber: season, episodeNumber: number)
            candidates[key] = candidates[key] ?? EpisodeProgressCandidate(
                seriesID: seriesID, season: season, number: number, episodeID: viewing.tmdbID,
                title: viewing.title, airDate: nil, watchedAt: viewing.watchedAt
            )
        }
        return Array(candidates.values)
    }

    private struct EpisodeEvent {
        let id: UUID
        let seriesID: Int
        let episodeID: Int
        let season: Int
        let number: Int
        let title: String
        let watchedAt: Date
    }

    private struct MovieEvent {
        let id: UUID
        let tmdbID: Int
        let title: String
        let watchedAt: Date
    }

    /// Merge both history sources. Their deterministic identities collapse duplicate
    /// representations of the same watch while retaining distinct rewatch dates.
    private static func episodeEventCandidates(_ payload: SeenrImportPayload) -> [EpisodeEvent] {
        var events: [UUID: EpisodeEvent] = [:]
        for viewing in payload.viewings where viewing.kind == "episode" {
            guard let seriesID = viewing.seriesID, let season = viewing.season,
                  let number = viewing.episode, seriesID > 0, season >= 0, number > 0 else { continue }
            let key = "episode|\(seriesID)|\(season)|\(number)|\(viewing.watchedAt.timeIntervalSince1970)"
            let id = eventID(key)
            events[id] = EpisodeEvent(
                id: id, seriesID: seriesID, episodeID: viewing.tmdbID,
                season: season, number: number, title: viewing.title, watchedAt: viewing.watchedAt
            )
        }
        for episode in payload.episodes {
            var dates = episode.dates
            if let watchedAt = episode.watchedAt, !dates.contains(watchedAt) {
                dates.append(watchedAt)
            }
            for watchedAt in dates {
                let key = "episode|\(episode.seriesID)|\(episode.season)|\(episode.number)|\(watchedAt.timeIntervalSince1970)"
                let id = eventID(key)
                events[id] = events[id] ?? EpisodeEvent(
                    id: id, seriesID: episode.seriesID,
                    episodeID: episode.tmdbID ?? episode.number,
                    season: episode.season, number: episode.number,
                    title: episode.title, watchedAt: watchedAt
                )
            }
        }
        return Array(events.values)
    }

    private static func movieEventCandidates(_ payload: SeenrImportPayload) -> [MovieEvent] {
        var events: [UUID: MovieEvent] = [:]
        for viewing in payload.viewings where viewing.kind == "movie" {
            let id = eventID("movie|\(viewing.tmdbID)|\(viewing.watchedAt.timeIntervalSince1970)")
            events[id] = MovieEvent(id: id, tmdbID: viewing.tmdbID, title: viewing.title, watchedAt: viewing.watchedAt)
        }
        for movie in payload.movies {
            var dates = movie.dates
            if let firstWatch = movie.watchedAt, !dates.contains(firstWatch) {
                dates.append(firstWatch)
            }
            for watchedAt in dates {
                let id = eventID("movie|\(movie.tmdbID)|\(watchedAt.timeIntervalSince1970)")
                events[id] = events[id] ?? MovieEvent(id: id, tmdbID: movie.tmdbID, title: movie.title, watchedAt: watchedAt)
            }
        }
        return Array(events.values)
    }

    private static func mappedStatus(_ raw: String) -> LibraryStatus? {
        switch raw.lowercased() {
        case "watchlist", "want_to_watch", "planned": .wantToWatch
        case "watching", "in_progress": .watching
        case "completed", "watched", "up_to_date", "uptodate": .watched
        case "monitoring", "upcoming", "returning": .monitoring
        default: nil
        }
    }

    private static func unknownStatusWarnings(_ payload: SeenrImportPayload) -> [String] {
        let unknown = Set((payload.shows + payload.movies).map(\.status).filter { mappedStatus($0) == nil })
        return unknown.sorted().map { "Statusen '\($0)' känns inte igen och titlar med den statusen hoppas över." }
    }

    private static func incompleteWatchHistoryWarnings(_ payload: SeenrImportPayload) -> [String] {
        let titlesWithMissingDates = (payload.shows + payload.movies).filter { record in
            let knownDates = Set(record.dates + (record.watchedAt.map { [$0] } ?? []))
            return record.watchCount > knownDates.count
        }.count
        let episodesWithMissingDates = payload.episodes.filter { record in
            let knownDates = Set(record.dates + (record.watchedAt.map { [$0] } ?? []))
            return record.watchCount > knownDates.count
        }.count

        guard titlesWithMissingDates > 0 || episodesWithMissingDates > 0 else { return [] }
        return ["Seenr anger antal visningar som överstiger antalet sparade datum för \(titlesWithMissingDates) titlar och \(episodesWithMissingDates) avsnitt. Extra visningar utan datum kan inte återskapas som separata historikhändelser."]
    }

    /// Stable UUID derived from the source event identity so importing the same export twice is safe.
    private static func eventID(_ value: String) -> UUID {
        func hash(_ input: String, seed: UInt64) -> UInt64 {
            input.utf8.reduce(seed) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
        }
        let a = hash(value, seed: 14_695_981_039_346_656_037)
        let b = hash(value, seed: 10_995_116_282_11)
        let raw = String(format: "%08x-%04x-%04x-%04x-%012llx",
                         UInt32(truncatingIfNeeded: a >> 32),
                         UInt16(truncatingIfNeeded: a >> 16),
                         UInt16(truncatingIfNeeded: a) | 0x5000,
                         UInt16(truncatingIfNeeded: b >> 48) | 0x8000,
                         b & 0x0000_FFFF_FFFF_FFFF)
        return UUID(uuidString: raw) ?? UUID()
    }
}
