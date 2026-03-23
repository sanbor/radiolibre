# Changelog

## 2026-03-23 — Technical review: fix convention violations and code quality issues

**Prompt:** `/implement perform a general technical review of code and architecture and recommendations of things to improve`

**Changes:**
- Removed Combine dependency from `PlayerViewModel` — replaced `AnyCancellable` sink with a polling `Task` that monitors AudioPlayerService state changes every 100ms, eliminating the only Combine usage in the project
- Replaced `withCheckedThrowingContinuation` bridging in `RadioBrowserService.performRequest()` with native `URLSession.data(from:)` async API (available iOS 15+)
- Eliminated force unwraps: consolidated `ServerDiscoveryService` fallback URL into a single `static let`, replaced `ImageCacheService` init `first!` with `guard let` + `fatalError`, replaced `FullPlayerView` URL force unwrap with conditional `if let`
- Improved `NowPlayingService` remote command handlers to return `.noActionableNowPlayingItem` when weak references are nil instead of silently returning `.success`
- Extracted duplicate tag parsing logic from `StationDTO` and `FavoriteStation` into shared `String.asTagList` extension (`String+TagList.swift`)
- Improved `HomeViewModel` error mapping — now distinguishes `URLError` codes instead of mapping all unknown errors to `.networkUnavailable`
- Extracted magic numbers in `LiveActivityService` (`staleInterval`) and `ImageCacheService` (`memoryCacheLimit`) to named constants
- Added technical review implementation notes to `PLAN.md` documenting findings, fixes, and remaining recommendations

## 2026-03-22 — Revert alphabet index to simple direct-mapping scroll

**Prompt:** `/implement recently there was an improvement to the alphabet index for sorted lists in browse section. the alphabet functionality is too hard to use because scrolling through the list is very cumbersome. I like the idea of having alphabet + numbers + # symbol for everything else. Go back to the old way of scrolling though the index list`

**Changes:**
- Reverted `AlphabetIndexView` from the GeometryReader/clipping/auto-scroll implementation back to the simple VStack with direct linear gesture mapping
- Removed overflow handling (scroll offset, clipped container, fraction-based centering) — all letters are now rendered at full height with direct finger-to-letter mapping
- Kept the alphabet + numbers + `#` section categorization unchanged (that logic lives in the list views, not AlphabetIndexView)

## 2026-03-22 — Track history browsing in full player

**Prompt:** `/implement in expanded listening now, where the name of artist/song is displayed, show left arrow (and right arrow if left arrows was pressed) so the user can read previously listenes songs. If the user taps in the name of the current song, show a history list of every played song and a timestamp. When there is no artist and song available, write the station name`

**Changes:**
- Added `TrackHistoryItem` model for in-memory, session-scoped track metadata history
- Added `trackHistory` array to `AudioPlayerService`, populated from ICY metadata in `parseStreamTitle` with dedup against consecutive identical entries
- Added track browse index and navigation methods to `PlayerViewModel` (`browseTrackBack`, `browseTrackForward`, `browsedTrackTitle`, `browsedArtist`)
- Replaced the static track info section in `FullPlayerView` with left/right chevron browse controls
- Station name shown as fallback when no ICY metadata is available
- Created `TrackHistorySheet` view — tapping track info opens a sheet with full session history (reverse chronological, with relative timestamps)
- Track history is cross-station and survives stop/station changes (session-scoped, not persisted)
- Added 24 new tests across `TrackHistoryItemTests`, `AudioPlayerServiceTests`, and `PlayerViewModelTests`

## 2026-03-22 — Show country + subdivision in full player

**Prompt:** `/implement show {country flag} {country full name} {countrysubdivision}. For example 🇳🇱 Netherlands, Amsterdam. If there is no countrysubdivision, just show 🇳🇱 Netherlands`

**Changes:**
- Changed full player country/language section to show flag + full country name + subdivision (e.g. "🇦🇷 Argentina, Buenos Aires") instead of flag + country + language
- If no subdivision is available, shows just flag + country name (e.g. "🇳🇱 Netherlands")
- Language is no longer displayed in the full player location line
- Modified `FullPlayerView.swift` only — no model changes needed

## 2026-03-22 — Fix language sorting by name with diacritics and overflow

**Prompt:** `/implement fix sorting by name in the language section. there was a previous attempt to fix it already`

**Changes:**
- Fixed `LanguageListView.sectionedLanguages` to fold diacritics when computing section keys (č → C, ö → O, ś → S) using `String.folding(options:locale:)`, so accented Latin languages sort with their base letters instead of after Z
- Non-Latin scripts (Cyrillic, CJK, Arabic) are grouped under a single trailing "#" section instead of creating dozens of individual sections
- Updated `AlphabetIndexView` to handle overflow: uses `GeometryReader` to detect when letters exceed available height, clips the VStack, and scrolls the sidebar to keep the selected letter visible during drag
- Added `languageSectionKey(for:)` helper function (internal, testable) extracted from the sectioning logic
- Added 4 new tests for section key computation: plain Latin, diacritics folding, non-Latin grouping, edge cases

## 2026-03-22 — Persist lock screen info after stop

**Prompt:** `/implement when the user press stop in the locked screen keep the star button, the station image, and the station name and current tune`

**Changes:**
- Added `stopNowPlaying()` method to `NowPlayingService` that sets `playbackRate = 0` while preserving all metadata (station name, artwork, track info, like button state)
- Changed `AudioPlayerService.stop()` to call `stopNowPlaying()` instead of `clearNowPlaying()`, so lock screen/Control Center retains station info after stop
- Fixed `handleLikeCommand()` to fall back to `lastPlayedStation` when `currentStation` is nil, making the star button functional even after stop
- Added 3 new tests: `testStopNowPlayingPreservesInfo`, `testStopNowPlayingPreservesArtist`, `testStopNowPlayingPreservesStreamMetadata`
- Updated SPEC.md and PLAN.md to document the new stop behavior

## 2026-03-22 — Filter junk language entries in Browse

**Prompt:** `/implement fix the languages section in browse which looks bad when sorting by name`

**Changes:**
- Added filtering in `BrowseViewModel.sortedLanguages` to exclude language entries whose names start with non-letter characters (`#`, `+`, digits, symbols) or have zero stations
- Filter uses `Character.isLetter` which is Unicode-aware, preserving legitimate names in any script (Latin, Cyrillic, Arabic, CJK, etc.)
- Added 4 new tests covering junk filtering, non-Latin script preservation, zero station count exclusion, and whitespace trimming
- Updated SPEC.md to document the filtering behavior

## 2026-03-22 — Home redesign

**Prompt:** `/implement make the home section better regarding font sizes and empty spaces. Also make sections look better.`

**Changes:**
- Replaced `List(.insetGrouped)` with `ScrollView` + `LazyVStack` in HomeView for a fluid, edge-to-edge layout without grouped card backgrounds
- Increased section title font from `.headline` to `.title2.bold()` to have bold typography
- Enlarged station cards: width 130→160pt, favicon 64→80pt, name font `.caption`→`.subheadline`
- Tightened spacing between sections and cards for better content density
- Styled vertical sections (Recently Changed, Now Playing) with rounded containers and dividers
- Fixed pre-existing Simulator crash in `AudioPlayerService.setupRouteDetector()` by guarding `AVRouteDetector` KVO with `#if !targetEnvironment(simulator)`
