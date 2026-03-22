# Changelog

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
