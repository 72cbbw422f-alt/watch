# WATCHLIST — Project Brief

## Product
A personal iPhone app for discovering films and series, managing a watchlist, tracking episode progress, browsing upcoming premieres and receiving local reminders.

## Product principles
- Native SwiftUI experience.
- Cinematic Premium visual identity; see DESIGN.md.
- Local-first personal library using SwiftData.
- TMDB as primary metadata source.
- Swedish market defaults: locale sv-SE and provider region SE.
- No account/backend requirement for the first release.
- Keep user-owned data separate from remotely refreshed catalogue metadata.
- Build incrementally; every milestone must produce a testable app.

## Platforms and baseline
- iPhone first.
- Swift and SwiftUI.
- Minimum deployment target: iOS 17 unless dependency/API needs justify a change.
- XcodeGen project generation.
- GitHub Actions using macOS runners.

## Version 1.0 scope
1. Home dashboard.
2. Discover and search for movies and TV.
3. Movie and series detail pages.
4. Personal library and custom watch statuses.
5. Episode and season progress tracking.
6. Premiere calendar (month and agenda views).
7. Local notifications for user-selected premieres.
8. Swedish streaming availability when supplied by the data source.
9. Settings for region, reminders and data attribution.

## Data sources
- TMDB API: movie, TV, season, episode, images, search, trending, discover and watch-provider data.
- TVmaze may be added as a supplementary episode schedule source after validating matching and date quality.
- Treat release dates as source data, not guarantees. Store source, region, precision and last-checked time where relevant.
- Streaming availability can vary by region and date; display attribution and link/provider information only when present in API data.

## Architecture
Use feature-oriented MVVM with clear boundaries:
- App: composition root and app lifecycle.
- Core: design system, shared utilities and extensions.
- Domain: app-owned models and business rules.
- Data: SwiftData persistence, DTOs, mappers and repositories.
- Networking: API client and source-specific clients.
- Services: notifications, image loading, calendar/event coordination.
- Features: independent screen flows and view models.

Prefer protocol-backed repositories so UI and tests do not depend directly on network implementations.

## Persistence principles
- Keep catalogue metadata distinct from user state.
- User state includes watch status, custom lists, ratings, notes, watched episodes and reminder preferences.
- Use stable external IDs plus media type for remote identity.
- Make sync/update operations idempotent.
- Never delete user-owned state merely because a remote API item is temporarily missing.

## Notifications
- Use local notifications for scheduled reminders.
- Schedule only events with sufficiently reliable dates.
- Reconcile pending notifications when dates change; prevent duplicates.
- Do not depend on iOS background execution running at an exact daily time.
- Ask permission contextually, after the user enables a reminder.

## Security and configuration
- Never commit API credentials.
- Provide an example configuration file and document local setup.
- Treat a client-embedded API key as extractable; keep early use within permitted personal/non-commercial terms and review a backend/proxy or other protection before wider distribution.
- Respect TMDB attribution and branding requirements.

## Quality gates
- Build succeeds in CI.
- Unit tests cover mapping, persistence rules, calendar date handling and reminder reconciliation.
- UI tests cover core navigation and add-to-library flow.
- Test loading, empty, offline and API-error states.
- Test on a physical iPhone before calling a milestone complete.

## Milestones
- M0: repository and build foundation.
- M1: design system and navigation shell.
- M2: TMDB search and catalogue detail.
- M3: local library and episode tracking.
- M4: premiere calendar and reminders.
- M5: streaming availability, polish and release candidate.

## Current status (2026-11-25)

The repository now includes the SwiftUI app shell, Cinematic Premium home screen, TMDB movie/TV search, localized weekly trending feed, poster artwork, and a navigable catalogue detail screen. The detail screen displays backdrop/poster art, synopsis, year and rating.

SwiftData persistence is now wired at the app root. `LibraryEntry` stores the user's saved catalogue metadata separately from the TMDB API, with three personal statuses: Want to watch, Watching and Watched. The detail screen can add a title to the library, change its status or remove it. The Library tab now lists saved titles, filters by status and links back to detail screens. Home trending posters open detail screens and the movie/series filters affect the displayed trending feed.

Favorites are implemented: titles can be marked from the detail screen and filtered in the Library tab. The Library also shows live counts for watched titles, currently watching titles and favorites. The Home screen's currently-watching shelf is backed by saved library entries. Watched-episode progress is now persisted separately in SwiftData through `EpisodeProgress`, using a stable series/season/episode key. Episode rows can be marked watched or unwatched, and each season reflects its saved watched count. The detail page also shows aggregate series progress as watched episodes out of the total episode count, with a progress bar. Unit tests cover stable identifiers, state changes and in-memory persistence. A live premiere calendar is now connected to the Calendar tab. It loads upcoming Swedish movie releases and future TV-series premiere dates from TMDB's discover endpoint, groups dated entries by day, and links each entry to its detail page. Remaining work: validate calendar behavior with live TMDB credentials, add user-selected premiere reminders, refine month/agenda navigation, and complete physical-device testing. The home hero has been simplified into a restrained editorial layout. Discover results now use open editorial rows with neutral metadata rather than stacked bordered cards. Library statistics are presented as a compact horizontal summary, and selected filters use a restrained outline instead of a filled accent capsule. The detail page keeps title and media type in the artwork header, with year and rating shown separately as understated metadata. Repeated year/rating labels in the artwork header have been removed. Library mutations now surface SwiftData save failures through an alert instead of silently swallowing persistence errors. CI build-for-testing has passed on the latest verified commits. Added focused SwiftData unit tests for default status, favorite defaults, status timestamp updates, invalid stored status fallback, MediaItem round-tripping, and in-memory insert/fetch/delete. The GitHub Actions workflow previously passed simulator unit tests in run #69. Later hosted-runner images lacked an available iOS Simulator runtime, and Apple's platform download command failed to connect. CI now performs a signing-free generic iOS Simulator build-for-testing so source and test targets can be compiled without depending on a preinstalled simulator device. The generic iOS Simulator build-for-testing passed in run #82. Actual simulator test execution remains to be restored. Added TV season/episode domain models, TMDB endpoints for series details and individual seasons, and a detail-page section that loads regular seasons and expands them into episode lists. Added decoding tests for season metadata and episode identifiers. No installable IPA or physical-device test is confirmed yet. TMDB token remains intentionally absent from source control; configure it using TMDB_SETUP.md.


## Visual quality direction (2026-11-25)
The visual system has been refined toward a mature premium editorial look: graphite surfaces, warm champagne/amber accent, restrained decoration, neutral information styling and stricter rules against placeholder-like or juvenile UI. See DESIGN.md for the professional finish checklist.
