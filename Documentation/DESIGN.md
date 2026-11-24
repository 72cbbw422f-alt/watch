# WATCHLIST — Design System

## Vision
WATCHLIST is a premium, cinematic personal film and television companion. The interface must feel editorial, immersive and unmistakably native to iOS — never like a generic media catalogue or an admin dashboard.

## Art direction: Cinematic Premium
- Immersive, edge-to-edge key art where it adds meaning.
- Confident editorial typography with clear hierarchy.
- Deep near-black foundations, layered graphite surfaces and restrained warm highlights.
- A distinctive electric-lime accent for primary actions, progress and selected states; use sparingly.
- Poster artwork is the hero. UI chrome must support it, not compete with it.
- Rich but controlled depth: gradients, subtle blur, layered materials and soft separators.
- Motion should feel intentional, fluid and fast. Use transitions to connect a poster to its detail page, not decorative animation everywhere.

## Color tokens
Initial design tokens (refine after first device screenshots):
- Background: #08090B
- Background elevated: #111318
- Surface: #171A20
- Surface elevated: #20242C
- Primary text: #F5F5F2
- Secondary text: #A5A9B2
- Muted text: #737985
- Accent lime: #C6F36A
- Accent pressed: #A8D94A
- Divider: white at 8–10% opacity
- Warm premium highlight: #D8C39A (rare, metadata only)

Do not use lime as a large page background. Reserve it for meaningful actions, active states, progress and small highlights.

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
