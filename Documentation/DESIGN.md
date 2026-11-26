# WATCHLIST — Design System

## Vision
WATCHLIST is a premium, cinematic personal film and television companion. The interface must feel editorial, immersive and unmistakably native to iOS — never like a generic media catalogue or an admin dashboard.

## Art direction: Graphite / Champagne

The visual language is deliberately mature and restrained: a premium editorial film journal, not a gaming interface or a brightly colored streaming clone. Prioritize composition, typography, image quality and whitespace over decorative effects.
- Immersive, edge-to-edge key art where it adds meaning.
- Confident editorial typography with clear hierarchy.
- Deep graphite foundations with subtle tonal separation; avoid pure-black-on-black stacking.
- Muted champagne/amber as a rare accent for primary actions, selected states and meaningful progress.
- Poster artwork is the hero. UI chrome must support it, not compete with it.
- Quiet depth: fine separators, restrained gradients and natural system materials only where useful.
- Motion should feel intentional, fluid and fast. Use transitions to connect a poster to its detail page, not decorative animation everywhere.
- The overall impression should be cinematic, understated, confident and expensive. Never juvenile, neon-heavy, toy-like or visually noisy.

## Color tokens
Initial design tokens (refine after first device screenshots):
- Background: #0B0C0E
- Background elevated: #121417
- Surface: #191C20
- Surface elevated: #24282D
- Primary text: #F1EEE9
- Secondary text: #B4B0AA
- Muted text: #817D77
- Muted champagne amber: #D49A68
- Accent pressed: #B77A4A
- Accent glow: orange at low opacity, used only behind selected hero actions or key moments
- Divider: white at 8–10% opacity
- Neutral highlight: #D0C8BE (rare, metadata only)

Amber is an accent, not a page background. Reserve it for meaningful actions and selected states. Most icons and metadata should remain neutral. Avoid accent-colored decoration without functional meaning.

## Typography
- Use the system SF family as the foundation.
- Large editorial titles: bold/semibold, tight but readable tracking.
- Section titles: strong and compact.
- Metadata: small, restrained, high contrast.
- Avoid excessive all-caps. Use uppercase only for small labels and overlines.
- Support Dynamic Type and accessibility text sizes.

## Imagery
- Posters and backdrops should load progressively with placeholders and graceful failure states.
- Prefer wide cinematic backdrops for hero/detail surfaces and portrait posters for catalogue cards.
- Apply a dark readability gradient behind text over artwork.
- Never stretch artwork or show broken-image icons.
- Use consistent poster aspect ratios and deliberate cropping.

## Core experience
### Home
A cinematic editorial landing page:
1. Greeting / compact brand header with profile and notification access.
2. Featured title with large backdrop, concise metadata and clear actions.
3. Continue watching row with progress.
4. Your watchlist row.
5. Upcoming premieres preview.
6. Curated discovery row.

The first screen must feel composed, not crowded. Keep the hero dominant and limit competing sections.

### Discover
- Search entry point is immediately visible.
- Editorial shelves for trending, popular, top rated and upcoming.
- Filter controls should be compact and tactile.
- Distinguish movies and TV clearly without splitting the app into disconnected experiences.

### Library
- Personal lists and status filters: Want to Watch, Watching, Completed, Paused.
- Poster-first grid with a useful compact list option.
- Empty states should be designed moments, not blank screens.

### Detail
- Large backdrop with gradient and poster/title hierarchy.
- Primary action changes by state: Add to Watchlist, Continue Watching, Mark Watched.
- Clear synopsis, genres, release details, cast, seasons and streaming availability.
- Secondary information should not overwhelm the main action.

### Series and episodes
- Season selector with clear progress.
- Episode rows with still image where available, title, runtime and watched state.
- One-tap episode completion and explicit progress.

### Premiere calendar
- Month, week and agenda/list modes.
- Clear visual distinction between movie premieres, new seasons and episodes.
- Date certainty must be explicit; do not imply a confirmed date when source data is approximate.
- Calendar events link directly to the relevant title.

### Notifications
- A polished notification inbox with upcoming reminders and read/unread state.
- Per-title reminder preferences.
- Avoid duplicate reminders when dates are refreshed.

## Navigation
Five primary destinations:
- Home
- Discover
- Library
- Calendar
- Profile

Use native iOS navigation patterns. On current iOS, use system Liquid Glass for navigation and controls where appropriate; do not recreate glass everywhere.

## Motion and interaction
- Poster-to-detail matched transitions where feasible.
- Subtle spring response for selection and add-to-list actions.
- Skeleton loading for remote content.
- Haptics for meaningful actions only.
- No long intro animations, excessive parallax or motion that delays access to content.

## Accessibility and quality bar
- Maintain strong text contrast; never rely on color alone for status.
- Respect Reduce Motion, Dynamic Type and Increase Contrast.
- All interactive targets must be comfortably tappable.
- Test on real iPhone screen sizes.
- Every screen needs loading, error, empty and populated states.
- Avoid layout shifts when artwork loads.

## Definition of “wow”
A screen is not finished because it compiles. It is finished when:
1. The visual hierarchy is immediately obvious.
2. Artwork and typography feel intentionally composed.
3. It looks excellent with real TMDB data, not just mock content.
4. Scrolling and transitions feel smooth on a physical iPhone.
5. Loading, empty and error states receive the same design attention.
6. It remains legible and usable with accessibility settings enabled.


## Professional finish — non-negotiable rules
- No oversized decorative sparkles, glowing blobs or gradients used as filler.
- Avoid excessive capsules, outlined cards and stacked containers. Prefer clean alignment and whitespace.
- Do not render the same title twice on a detail page; the hero owns the title.
- Use one clear primary action per screen, with secondary actions visually quieter.
- Statistics are information, not decoration: neutral icons, restrained numerals and no unnecessary accent color.
- Avoid tiny uppercase labels when a normal-case title communicates better.
- Use consistent spacing, corner radii and poster ratios across all features.
- Never use placeholder copy that pretends a feature is live. Clearly communicate what is available.

## Product-design benchmark — established media apps

Use the interaction quality and information architecture of leading film and television products as the benchmark, while keeping WATCHLIST's own visual identity. Do not copy their branding or reproduce their interfaces pixel-for-pixel.

Reference patterns to learn from:
- **Letterboxd:** poster-led discovery, strong film identity, clear personal ratings and watchlist actions, editorial hierarchy.
- **Trakt:** practical tracking workflows, clear watched / watching / planned states, season and episode progress, useful activity history.
- **TV Time:** approachable series tracking, next-episode context, season progress and fast episode completion.
- **JustWatch:** efficient discovery, clear movie-versus-series distinction, filters and useful metadata density.
- **Apple TV:** confident full-bleed artwork, restrained typography, native-feeling navigation and polished transitions.

Translate those patterns into one coherent native iOS product:
- Home is a curated entertainment front page, not a welcome page with a large slogan.
- Discover opens with real shelves: trending, popular, top rated and upcoming. Search is always easy to reach.
- Search results use poster artwork, title, year, type, rating and a readable synopsis. Results must not look like web search snippets.
- Detail pages lead with backdrop and poster, then title, year, runtime/seasons, genres, rating, synopsis and one unmistakable primary library action.
- Library is a visual collection first: poster grid as the default, compact list as an alternative, fast status and favorite filters.
- Series tracking makes season and episode progress obvious and quick to update.
- Calendar and progress views should look like finished product screens, not generic data tables.
- Navigation stays consistent and native. Avoid redundant navigation levels and oversized empty states.

## Visual quality gates

A screen is not accepted if it resembles a website template or an early-2000s portal. Specifically:
- No giant empty vertical gaps, oversized decorative icons, or text-only landing screens when artwork is available.
- No long stacks of bordered rounded rectangles. Use layout, imagery and typography to create hierarchy.
- No tiny metadata that requires squinting. Secondary information must remain comfortably legible.
- Poster ratios, image crops, card spacing and typography must be consistent across the app.
- Primary actions must be obvious and reachable; secondary actions must not compete with them.
- Loading, no-results, disconnected and error states must be intentionally designed and provide a useful next step.
- Every screen must be judged with real TMDB artwork and on a physical iPhone, not only in a simulator.
- Prefer native SwiftUI controls and platform conventions over web-like controls.

The goal is not to make WATCHLIST look like a streaming service. It is to combine the best tracking and discovery patterns of established apps into a polished personal film and TV library.


## User-approved visual reference direction — November 2026

The supplied App Store references (Bingebase, FilmNoir, Queue, Refract and related media trackers) establish the user's preferred product character. Use them as interaction and visual-quality references, not as templates to copy.

### Visual character
- Keep the WATCHLIST graphite foundation, but let the warm orange accent read more clearly and confidently, closer to the references.
- Use cinematic artwork as a first-class layout element: full-bleed backdrops on feature/detail screens, portrait posters in shelves and grids, and episode stills in progress views.
- Prefer compact, information-rich screens with strong spacing discipline. Avoid large unused gaps, but do not compress text or tap targets.
- Use rounded surfaces and restrained glass/material treatments selectively. Orange outlines, progress bars and selected controls should communicate state, not act as decoration.
- Use editorial headings with confident weight and clear title/metadata hierarchy. Keep secondary labels readable.
- The app should feel like a personal media command centre: polished, fast to scan, and useful every day.

### Reference patterns to prioritize
1. **Home:** Continue watching, planned/watchlist, trending shelves, upcoming releases and personalized selections. Each shelf should have a clear purpose and an artwork-led presentation.
2. **Library:** Poster grid, status filters, movie/series switch, sorting and custom collections. Show useful counts and progress without crowding the artwork.
3. **Title detail:** Backdrop plus poster/title, synopsis, genres, release facts, ratings where available, watch status, favorite/list/review actions, and season/episode progress for series.
4. **Progress:** A practical queue of next episodes with season/episode labels, progress indicators and one-tap completion. Keep history and statistics accessible.
5. **Calendar:** Month and agenda views with clear premiere/episode distinctions and poster-linked events.
6. **Statistics/profile:** Watch time, completed titles, episodes, streaks, genre breakdown and personal ratings, presented as meaningful data rather than decorative charts.
7. **Smart lists:** Saved collections with filters and sorting that can be revisited quickly.
8. **Availability and integrations:** Where-to-watch information and import/export should be clearly separated from core tracking and should never be presented as live unless the data source supports it.

### Implementation discipline
- Preserve WATCHLIST's own identity; do not copy third-party logos, exact layouts, labels or proprietary visual treatments.
- Build coherent end-to-end flows rather than isolated showcase screens.
- Prefer real TMDB artwork and metadata. Clearly distinguish unavailable data from a genuine empty result.
- Before changing navigation, map every destination and keep the primary tab bar to a deliberate, consistent set of destinations.
- Validate horizontal content insets on the actual iPhone width: hero content, section headings, filters and poster shelves must align to the same screen coordinate system. Horizontal carousels may scroll, but their parent page must never shift sideways.
