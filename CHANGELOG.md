# Changelog

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
