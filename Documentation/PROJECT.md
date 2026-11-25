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

Favorites are implemented: titles can be marked from the detail screen and filtered in the Library tab. The Library also shows live counts for watched titles, currently watching titles and favorites. The Home screen's currently-watching shelf is backed by saved library entries. Watched-episode progress is now persisted separately in SwiftData through `EpisodeProgress`, using a stable series/season/episode key. Episode rows can be marked watched or unwatched, and each season reflects its saved watched count. The detail page also shows aggregate series progress as watched episodes out of the total episode count, with a progress bar. Unit tests cover stable identifiers, state changes and in-memory persistence. A live premiere calendar is now connected to the Calendar tab. It loads upcoming Swedish movie releases and future TV-series premiere dates from TMDB's discover endpoint, groups dated entries by day, and links each entry to its detail page. The calendar now offers both an agenda view grouped by date and a month grid with marked premiere days and a selected-day event list. A dedicated saved-reminders overview is accessible from the calendar toolbar; it lists saved reminders by premiere date and supports swipe-to-remove with notification cancellation after a successful persistence save. It supports user-selected local premiere reminders (one week before, the day before, or on the premiere day). Reminder preferences are stored in SwiftData, notification permission is requested only when a reminder is enabled, and removing a reminder cancels its pending notification. Users can change an existing reminder's lead time. When refreshed TMDB data contains a changed premiere date for a saved reminder, the app attempts to reschedule its notification and persist the new date. Reminder mutations now persist SwiftData changes before scheduling or cancelling system notifications, and revert the model change if notification scheduling fails, reducing the risk of saved preferences and pending notifications diverging. A persistence test covers the reminder model. Remaining work: verify notification scheduling and date-change reconciliation on device, validate calendar behavior with live TMDB credentials, refine month/agenda navigation, and complete physical-device testing. The home hero has been simplified into a restrained editorial layout. Discover results now use open editorial rows with neutral metadata rather than stacked bordered cards. Library statistics are presented as a compact horizontal summary, and selected filters use a restrained outline instead of a filled accent capsule. The detail page keeps title and media type in the artwork header, with year and rating shown separately as understated metadata. Repeated year/rating labels in the artwork header have been removed. Library mutations now surface SwiftData save failures through an alert instead of silently swallowing persistence errors. CI build-for-testing has passed on the latest verified commits. Added focused SwiftData unit tests for default status, favorite defaults, status timestamp updates, invalid stored status fallback, MediaItem round-tripping, and in-memory insert/fetch/delete. The GitHub Actions workflow previously passed simulator unit tests in run #69. Later hosted-runner images lacked an available iOS Simulator runtime, and Apple's platform download command failed to connect. CI now performs a signing-free generic iOS Simulator build-for-testing so source and test targets can be compiled without depending on a preinstalled simulator device. The generic iOS Simulator build-for-testing passed in run #82. Actual simulator test execution remains to be restored. Added TV season/episode domain models, TMDB endpoints for series details and individual seasons, and a detail-page section that loads regular seasons and expands them into episode lists. Added decoding tests for season metadata and episode identifiers. No installable IPA or physical-device test is confirmed yet. TMDB token remains intentionally absent from source control; configure it using TMDB_SETUP.md.


## Visual quality direction (2026-11-25)
The visual system has been refined toward a mature premium editorial look: graphite surfaces, warm champagne/amber accent, restrained decoration, neutral information styling and stricter rules against placeholder-like or juvenile UI. See DESIGN.md for the professional finish checklist.

Personal reviews are now part of each library entry: an optional private 1–10 rating and free-text notes, kept separate from TMDB's public rating. The title detail screen creates a library entry automatically when a user adds a personal rating or note to a title not yet saved. The Library list displays the personal rating and a note indicator where present. Persistence tests cover the empty defaults and in-memory save/fetch of review data. The new review UI and data model have been added; CI verification is in progress. No physical-device migration test has been completed yet.

Custom collections have now been added as local SwiftData models. Users can create named lists from the Library tab, open a list, navigate to its movie or series entries, remove entries, and add a catalogue title to any existing list from its detail screen. Membership identity is scoped to both list and media stable ID, so one title can appear in several lists while duplicate membership in the same list is prevented. Tests cover list-name normalization, same-title membership across multiple lists, stable membership identity and TV metadata round-tripping. Build verification is pending; migration and physical-device checks remain outstanding.


## Progress dashboard (2026-11-25)
A dedicated Progress tab now separates active, planned and completed TV series from the general library. It shows library counts, watched episode totals, poster-led series rows, search and status filters. Per-series progress percentages are displayed only after TMDB has supplied a known regular-season episode total on the title detail screen; otherwise the UI reports the known watched-episode count without inventing a denominator. The Progress tab reuses the existing local SwiftData library and episode progress. CI build verification pending; no physical-device validation completed.


Episode progress now records an optional watchedAt timestamp whenever a user marks an episode watched. Unmarking clears that timestamp. The Progress dashboard can use the timestamp to show viewing recency; older records without it retain dateUpdated as a fallback. This timestamp represents the moment the user marked an episode watched, not an imported historical date. CI verification pending.


## JSON backup import (2026-11-25)

The Profile backup screen now supports selecting a JSON backup, decoding and validating it, showing a pre-import summary, and explicitly confirming an additive merge. The import service previews new versus matching library IDs and counts episode states, viewing events, custom lists, memberships and reminders. The merge inserts missing records and deliberately leaves matching local library entries untouched; it does not delete local-only records. Event UUIDs and stable membership IDs prevent duplicate imports. Backup validation rejects unsupported schema versions, invalid identities, duplicate IDs and custom-list memberships whose parent list is absent. Tests cover preview counts and prove that an existing title and its personal notes are not overwritten by an imported duplicate. This is the generic WATCHLIST v1 JSON import path; it is not a Seenr importer. Seenr-specific mapping requires an actual export sample and must preserve whatever dates/fields that file really contains. CI verification and physical-device file-picker testing remain pending.

## JSON backup export (2026-11-25)

A versioned JSON backup schema (v1) and export service now serialize the local library, personal statuses, favorites, ratings, notes, episode progress, append-only episode viewing events, custom lists and memberships, and premiere reminders. Dates use ISO 8601. The payload is validated before encoding and after decoding, and unknown schema versions are rejected. The Profile tab now contains a backup screen that creates a local JSON file through the system file exporter; the export is generated from SwiftData and is not sent to a server. Tests cover round-trip preservation of personal library fields, export from an in-memory SwiftData store, and rejection of invalid library identity. Import/merge, conflict preview, and Seenr-specific mapping are not implemented yet.

## Episode viewing history (2026-11-25)

An append-only `EpisodeWatchEvent` model now records each manual action that marks an episode watched. Events have independent UUIDs and preserve series/episode identity, title, timestamp and source. Rewatching the same episode can therefore create another event without overwriting earlier viewing history. The existing `EpisodeProgress` model remains the current watched/unwatched state used for progress calculations; unmarking an episode does not erase past viewing events. Existing `watchedAt` values are not retroactively converted into historical events because they do not establish a complete viewing history. The model is registered in the app's SwiftData container, and tests cover multiple events for the same episode and persisted identity. The explicit rewatch action is implemented in the episode context menu. Import/export support for episode events is covered by the backup workflow. Physical-device migration checks remain pending.

The Progress screen now links to a chronological viewing-history screen. Each event shows the series title when it exists in the local library, episode identity/title, timestamp and event source. A watched episode also exposes an explicit context-menu action to register another viewing without changing its current watched state. The history screen now presents both film events and episode events in separate sections. Movie viewings are explicitly registered from the movie detail page; each registration creates a new immutable event, including rewatches. Movie events are included in JSON backup and additive restore.

## Next episode metadata (2026-11-25)
TV series detail decoding now reads TMDB's `next_episode_to_air` object. When a series detail page refreshes, the library snapshot stores the next episode title, season/episode code and air date. The Progress rows display the next episode and its published date when TMDB provides one. This uses the actual next-episode field, not the series `first_air_date`. CI verification pending.


The Progress row now distinguishes a next-episode air date that is today/past (`NYTT AVSNITT`) from a future date (`IKAPP`). This label is based only on TMDB's `next_episode_to_air.air_date`; when TMDB provides no next episode, no availability state is inferred. It does not yet replace a full episode-release sync or push notification system.


### Backup/import verification update (2026-11-25)

The additive JSON import is now covered by CI runs #186 and #187: the import notification restore call receives only the reminder IDs present in the selected backup, local-only library entries remain untouched, and importing the same backup twice is idempotent. A full restoration integration test has been added for episode progress, append-only episode history, custom lists, list memberships and premiere reminders; its CI run is pending. Notification scheduling remains conditional on existing notification authorization and still requires physical-device verification. Generic JSON import is not a Seenr importer; a real Seenr export sample is required before implementing source-specific mapping.


## Yearly viewing statistics (2026-11-25)

A new annual overview is available from the Progress dashboard. It combines append-only film and episode viewing events, showing total viewing occasions, unique episodes, unique films, additional viewing events, month-by-month activity, and the five most-viewed series and films. Users can switch between years represented in their history. Legacy watched-state records without a corresponding event are not retroactively counted. The combined movie/episode statistics and history query fixes compile in CI run #216 (generic iOS Simulator build-for-testing, success). This is a build verification only; no physical iPhone validation has been completed.


## Movie viewing history (2026-11-26)

An append-only `MovieWatchEvent` model records each explicit movie viewing registration with TMDB identity, title, poster path, timestamp and source. The movie detail page offers a dedicated registration action; each tap is a separate event, so rewatches are preserved. Registering a movie also ensures it exists in the library with watched status. The chronological history view now includes film and episode sections. Movie events are included in JSON export and additive import, with duplicate event IDs ignored. The optional `movieHistory` backup field preserves compatibility with earlier schema-v1 backups that do not contain this field. Automated export/restore tests have been added. The SwiftData model, import service, movie-history views and annual statistics compile in CI run #216 (generic iOS Simulator build-for-testing, success). Import idempotency coverage is being expanded; physical-device migration and UI checks remain pending.
