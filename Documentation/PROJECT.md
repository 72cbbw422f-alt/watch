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

Remaining work: verify the newest CI run, handle persistence errors visibly rather than silently, implement editing/favorites and a useful currently-watching home shelf, then build season/episode progress and the premiere calendar. No successful build or installable IPA is confirmed yet. TMDB token remains intentionally absent from source control; configure it using TMDB_SETUP.md.
