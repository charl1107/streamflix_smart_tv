# Android TV UI and Playback Remediation Plan

## Objective

Deliver a remote-first Android TV experience for Cineko/Streamflix that matches
the web UI's visual hierarchy while preserving correct movie, TV, and anime
playback routing at 1080p and 4K viewing distances.

## Current Findings

The app already has a useful TV foundation:

- Android Leanback launcher support, landscape mode, and immersive system UI.
- A reusable `TvFocusWrapper` for Select/Enter activation and visible focus.
- A dedicated TV player screen and server-switcher modal with widget tests.

The following issues need attention:

| Area | Finding | Impact |
| --- | --- | --- |
| Media rails | A 245px media card is placed in a rail with a 180px height. | Cards and their focus outline/scale can be clipped. |
| Focus navigation | Focus visuals exist, but scroll-to-focused-item, recovery, and screen-entry rules are not defined. | Remote navigation can feel lost or trap users off-screen. |
| Header | The floating header overlays content and has no explicit entry/exit focus path. | Content can be obscured and D-pad movement is unpredictable. |
| Search | The input auto-focuses on opening Search. | Android TV may open the on-screen keyboard before the user asks for it. |
| Fixed layouts | Search and episode grids use fixed dimensions/column counts. | Layout and text density are not reliable across 1080p and 4K. |
| Season selection | The native dropdown needs remote-specific validation. | Season changes can be awkward or inaccessible with a D-pad. |
| Text encoding | Some UI labels contain malformed characters such as `â€”`, `â€¢`, and `â–²`. | Visible quality issue. |
| Anime banners | Anikoto returns its hero field as `background_image`, while the backend only mapped alternate names. | The anime hero falls back to a poster or appears visually incomplete. |
| Anime sources | AniList credentials remain in configuration but are not used by the current anime route. | Misleading configuration and no explicit MAL metadata fallback. |

## Scope

### In scope

- Android TV UI sizing, focus behavior, D-pad navigation, and screen layouts.
- Web UI visual parity, with only essential remote/large-screen adaptations.
- Home, Movies, Shows, Anime, Search, Detail, Episodes, Player, and server selection.
- Anikoto catalogue/episode playback with optional MAL-compatible metadata enrichment.
- Tests for routing, focus behavior, and representative TV viewport sizes.

### Out of scope unless separately approved

- Changing streaming providers or provider catalogues.
- Backend API redesign unrelated to episode routing.
- A separate mobile/desktop visual redesign.

## Delivery Method — Waterfall

Each stage is completed and approved before the next stage begins. Changes to a
completed stage are recorded as a change request and assessed for its impact on
the remaining stages.

| Stage | Objective | Exit criteria | Status |
| --- | --- | --- | --- |
| 1. Requirements | Lock the shared Flutter web UI reference, TV behavior, supported platforms, and acceptance criteria. | Approved requirements and a screen-by-screen parity checklist. | Complete |
| 2. Design | Produce responsive TV layouts, focus map, component specifications, and player interaction rules. | Approved design specification with 1080p and 4K states. | Complete |
| 3. Implementation | Build the approved UI, focus behavior, playback flow, and provider integration. | All approved source changes are complete. | In progress |
| 4. Verification | Run automated checks and device/emulator walkthroughs against the acceptance matrix. | No blocking defects; evidence recorded. | Not started |
| 5. Release | Refresh generated dependencies, build the Android TV artifact, and hand over release notes. | Release artifact and final test report are available. | Not started |

### Stage 1 — Requirements (complete)

1. [x] Use `streamflix_tv_app` and its Flutter web build as the approved visual
   reference for Home, Movies, Shows, Anime, Search, Detail, and Player.
2. [x] Create a screen-by-screen visual-parity checklist covering layout, colors,
   typography, cards, banners, empty/loading states, and player overlays.
3. [x] Lock the Android TV adaptations: focus treatment, D-pad paths, safe margins,
   large-screen type scale, on-screen keyboard behavior, and Back behavior.
4. [x] Confirm supported targets: Android TV at 1920x1080 and 3840x2160, plus any
   required emulator or physical-device version.
5. [x] Freeze the acceptance matrix before design work begins. The shared Flutter
   visual components remain the source of truth; Android TV changes must be
   behavioral or scale/safe-area adaptations, not a separate visual redesign.

### Stage 2 — Design (complete)

| Surface | Shared web UI retained | Android TV adaptation |
| --- | --- | --- |
| App navigation | Cineko branding, icons, destination order, colors, and selected state. | Safe-area header placement, a single directional traversal group, and a visible focus outline. |
| Hero banner | Backdrop, gradients, metadata, title, and Play/Details actions. | Bounded 16:9-inspired height so the first rail is visible at 1080p; TV-safe content margins. |
| Content rails | Card design, labels, ratings, and row titles. | Responsive card width/rail height, unclipped focus scale, and focused-card auto-scroll. |
| Search | Existing field, results, and empty/loading states. | Deliberate text-entry focus, adaptive grid columns, and TV-safe padding. |
| Detail and episodes | Existing content hierarchy and visual treatment. | Safe margins, larger focus targets, adaptive episode grid, and predictable Back behavior. |
| Player | Existing embedded player and server modal visual treatment. | Flutter-owned overlays take focus; provider-owned iframe controls remain isolated. |

**Layout tokens:** use a minimum 32px horizontal safe margin at 1080p, scale up
to 64px at 4K, bound hero height to approximately 52% of viewport height, use
responsive poster-card sizes, and reserve vertical clearance for the focus ring.

**Focus rules:** the first visible primary action receives initial focus; D-pad
uses Flutter's directional traversal; focused cards scroll into view; overlays
trap focus until Back dismisses them; returning from Detail or Player restores a
visible parent control.

### Stage 3 — Implementation (in progress)

1. [x] Add shared responsive TV layout tokens for safe margins, section gaps,
   hero height, poster dimensions, rail height, and grid column count.
2. [x] Apply the shared tokens to navigation, hero banners, media rails, cards,
   genre chips, loading placeholders, search, details, episodes, player chrome,
   and the server-switcher modal.
3. [x] Correct the card/rail size mismatch and allow rail focus effects to draw
   outside the scroll viewport.
4. [x] Add focus-driven scroll-to-visible behavior and reduce focused scale to
   preserve the existing web design without clipping.
5. [x] Prevent Search from automatically requesting text focus when its screen
   opens on Android TV.
6. [x] Make Search and episode grids adapt to the available TV viewport.
7. [x] Pause hero auto-rotation while a remote user is focused on its Play or
   Details control.
8. [x] Add widget coverage for 1080p/4K layout bounds and remote Select/focus
   presentation.
9. [x] Decouple anime episode loading from optional MAL metadata, preventing a
   slow metadata request from producing an empty episode view.
10. [x] Add and deploy a CORS-safe, host-restricted proxy for Anikoto CDN
   images so Flutter web can render anime posters and CDN backdrops.
11. [ ] Validate directional focus paths and focus restoration on an Android TV
   emulator or physical device.
12. [ ] Run the full formatter, analyzer, widget-test suite, and an Android
    release build; record visible output from a Flutter-enabled environment.
13. [ ] Refresh Flutter dependencies/generated plugin registrants only when a
    manifest dependency changes.
   formatter, analyzer, widget tests, and a release build in a Flutter-enabled
   environment.

## Implementation Plan

### Phase 1 — Baseline playback and UI-flow verification

1. Verify generic movie, TV episode, and anime episode selection flows before
   applying the UI refactor.
2. Confirm that selected titles, seasons, episodes, player arguments, and
   generated provider URLs remain unchanged by visual work.
3. Add regression coverage for representative movie, TV, and anime routes.

### Phase 2 — TV layout foundation

1. Create a shared TV layout helper for viewport-aware dimensions and safe
   margins.
2. Use the web UI as the source of truth for the header, hero, cards, rails,
   details, colors, and player overlays. Apply larger targets and focus states
   only where Android TV requires them.
3. Set clear layout targets for 1920x1080 and 3840x2160.
4. Define consistent TV spacing, title sizes, metadata sizes, control heights,
   card dimensions, and focus-ring clearance.
5. Replace only unsuitable fixed dimensions with responsive TV tokens; retain
   compact values where they already serve the layout.

### Phase 2A — Anime banner and provider migration

1. Map Anikoto's `background_image` into `backdrop_path` before falling back to
   the poster. This restores existing full-width hero artwork immediately.
2. Retain Anikoto as the catalogue identity and episode-playback provider,
   because its provider IDs and episode embed identifiers are required to open
   streams.
3. Use the Anikoto `mal_id` to optionally enrich an anime detail response from
   a MAL-compatible metadata API (Jikan). This provides a non-AniList metadata
   source without coupling playback to a catalogue that lacks Anikoto episode
   IDs.
4. Make MAL metadata failure-safe: if it is rate-limited, unavailable, or lacks
   an image, preserve Anikoto metadata and playback rather than failing the
   page.
5. Remove unused AniList OAuth/API configuration from tracked backend examples,
   Worker variables, and Flutter configuration. Do not add AniList credentials
   to clients or source control.
6. Expose source provenance in the normalized API response: Anikoto for
   catalogue/playback and MAL when enrichment succeeds.

### Phase 3 — Remote focus and navigation

1. Define one initial focus target for each screen:
   - Home, Movies, Shows, Anime: primary hero action or first content card;
   - Search: an explicit search activation control;
   - Detail: Back or primary playback action;
   - Player: player input surface.
2. Make D-pad movement predictable between the header, hero, filters, rails,
   grids, actions, and episode lists.
3. Scroll focused items into view in horizontal rails and vertical pages.
4. Preserve and restore focus when the user returns from a detail or player
   screen.
5. Standardize Select/Enter, Back, and dismiss behavior across controls and
   overlays.
6. Ensure focus scale, shadows, and borders are never clipped by a parent.

### Phase 4 — Global navigation and shared components

1. Refine `AppNavigation` into a TV-safe header/navigation treatment with
   predictable focus entry and exit.
2. Update `TvFocusWrapper` to provide consistent focus effects and optional
   focus visibility/scroll assistance.
3. Update `MediaCard` and `MediaRail` so card size, rail height, labels, and
   focus treatment agree.
4. Update `HeroBanner` to preserve an immediate view of the first content row
   at 1080p, while retaining clear Play and Details actions.
5. Update `GenreChips` and `EpisodeGrid` for readable labels, D-pad-friendly
   spacing, and adaptive sizing.

### Phase 5 — Screen-by-screen UI work

#### Home, Movies, Shows, and Anime

1. Apply safe margins and an appropriate hero height.
2. Give each rail a visible title, enough card clearance, and usable horizontal
   D-pad movement.
3. Restore focus to the correct rail/card after a detail-screen return.
4. Ensure loading, empty, and error states do not create dead-end focus.
5. When filtering by genre, transfer focus predictably to the new results.

#### Search

1. Replace automatic text input focus with deliberate remote activation.
2. Ensure D-pad users can reach the clear action and results without keyboard
   interference.
3. Use an adaptive results grid rather than a permanent five-column layout.
4. Retain query text and focused result when returning from a detail screen.

#### Detail and episodes

1. Rebuild the backdrop header with TV-safe placement and readable title,
   metadata, overview, and primary actions.
2. Make Play/Resume, season selection, episode selection, and Back obvious and
   reachable by remote.
3. Replace or enhance the season selector if native dropdown behavior is not
   suitable for Android TV.
4. Scale episode cards and avoid grid focus clipping.
5. Make cast entries focusable only if selecting them performs an action.
6. Retain the selected season and episode when coming back from playback.

#### Player and server selection

1. Confirm the player consumes the same media ID, season, and episode supplied
   by the detail screen.
2. Ensure changing server rebuilds the URL for the active episode and retains
   playback position where the provider supports it.
3. Verify player D-pad controls, server-modal focus trap, dismissal, loading,
   retry, and focus restoration.
4. Fix malformed UI text encoding in player and modal hints.

### Phase 6 — Quality and accessibility polish

1. Correct all malformed encoded strings.
2. Ensure text contrast and font sizes are appropriate for ten-foot viewing.
3. Add semantic labels where they improve accessibility.
4. Verify that every visible actionable control can be reached and activated
   with a standard Android TV remote.

## Verification Matrix

| Scenario | Required result |
| --- | --- |
| TV episode selection | The chosen season and episode remain intact when opening the player. |
| Later-season TV episode | Chosen season and episode both remain intact. |
| Movie | Opens the movie route without TV season/episode segments. |
| Anime episode | Opens the supported anime episode route. |
| Server change | Rebuilds the active title's route without resetting episode selection. |
| 1920x1080 | No overlapping header, clipped cards, or clipped focus state. |
| 3840x2160 | Type, card density, gaps, and safe margins scale appropriately. |
| D-pad paths | Every primary action has a predictable directional focus target. |
| Back | Dismisses overlays first, then returns to the prior screen and focus. |
| Search | Keyboard opens only after deliberate input activation. |

## Planned Code Areas

- `lib/config/theme.dart`
- `lib/navigation/app_navigation.dart`
- `lib/widgets/tv_focus_wrapper.dart`
- `lib/widgets/media_card.dart`
- `lib/widgets/media_rail.dart`
- `lib/widgets/hero_banner.dart`
- `lib/widgets/genre_chips.dart`
- `lib/widgets/episode_grid.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/movies_screen.dart`
- `lib/screens/shows_screen.dart`
- `lib/screens/anime_screen.dart`
- `lib/screens/search_screen.dart`
- `lib/screens/detail_screen.dart`
- `lib/screens/player_screen.dart`
- `lib/widgets/tv_server_switcher_modal.dart`
- Relevant player-routing and URL-generation tests.

## Definition of Done

1. Android TV users can complete all primary browse, search, detail, episode,
   player, and server-switching actions with a remote only.
2. Focus is always visible, unclipped, and restored predictably.
3. The UI matches the web product's approved visual design while remaining
   practical for TV remotes and viewing distance.
4. The UI is legible and balanced at 1080p and 4K.
5. Formatter, analyzer, and relevant widget/unit tests pass.
6. The handoff includes a concise test report and any remaining physical-TV
   observations.
