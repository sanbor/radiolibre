# LibreRadio

Native iOS internet radio player powered by the [Radio Browser](https://www.radio-browser.info/) community database (30,000+ stations). iOS counterpart to [RadioDroid](https://github.com/segler-alex/RadioDroid) (Android).

- iOS 16+, SwiftUI, no third-party dependencies
- License: GPL-3.0

> **Current status:** All MVP phases (1–7) and post-MVP phases 8–9 are complete. The app is fully functional with CarPlay and Live Activity support. Next up: post-MVP feature work (sleep timer, widgets, Siri shortcuts, etc.).

---

## Data Source

Uses the Radio Browser public API. No authentication or API keys.

### Server Discovery

Servers are discovered dynamically — never hardcoded.

1. DNS-resolve `all.api.radio-browser.info`, reverse-lookup each IP to get hostnames
2. Shuffle results for load balancing
3. Cache in UserDefaults with 24-hour TTL; reuse cache on failure
4. Last-resort fallback: `de1.api.radio-browser.info`

On any API failure, rotate to the next discovered server (round-robin) and retry once. If the retry also fails, surface the error.

### Error Handling

| Condition | User Message | Recovery Hint |
|---|---|---|
| No network | No internet connection | Check your internet connection |
| Server discovery failed | Could not discover radio servers | Service may be temporarily unavailable |
| HTTP 4xx/5xx | Server error (N) | Try again |
| Bad JSON | Failed to read server response | Server returned unexpected response |
| Invalid stream URL | Invalid stream URL | Try a different station |
| Audio session error | Audio session error | Try playing again |
| Playback failure | Playback failed | Try playing again |
| No servers available | No servers available | Service may be temporarily unavailable |

---

## Data Model

### Station

Identity: `stationuuid` (globally unique).

Fields: name, stream URL, resolved stream URL, homepage, favicon URL, tags (comma-separated), country, country code, state, language, language codes, codec, bitrate (kbps), HLS flag, votes, click count (24h), click trend, last check OK, last check time, geo coordinates.

Derived behavior:
- Tag list: split by comma, trim whitespace, drop empties
- Prefer resolved stream URL; fall back to raw URL
- Favicon/homepage: nil when empty string
- Favicon URLs: upgraded from `http://` to `https://` (ATS requires HTTPS for in-app image downloads via URLSession)
- Stream URLs: `http://` allowed as-is (`NSAllowsArbitraryLoadsForMedia`; many stations only support HTTP)
- Homepage URLs: no conversion needed (opened externally in Safari, which handles `http://` natively)
- Bitrate label: `"128k"` format, or `"—"` when zero/missing
- Online: last check OK = 1

### Country

Name, ISO 3166-1 alpha-2 code, station count.

### Language

Name, optional ISO 639 code, station count.

### Tag

Name, station count.

### Favorite Station

Locally persisted snapshot: station UUID, name, resolved URL, favicon URL, tags, country code, language, codec, bitrate, date added, sort order (for manual reordering).

### History Entry

Locally persisted record: unique ID, station UUID, name, resolved URL, favicon URL, codec, bitrate, country code, date played.

Rules:
- Max 50 entries; oldest deleted when full
- If same station replayed within 30 minutes, update the timestamp instead of inserting (prevents flooding from network reconnects)

---

## App Structure

### Tab Bar

| Tab | Icon | Screen |
|---|---|---|
| Home | house.fill | Home with curated sections |
| Recent | clock | Recently played stations |
| Search | magnifyingglass | Search with filters |
| Browse | list.bullet | Countries / Languages / Tags |
| Favorites | star.fill | Saved stations |

A mini player bar sits above the tab bar. Always visible with an idle state when no station is loaded.

---

## Home

Shows curated station sections at a glance.

| Section | Source | Limit | Layout | Condition |
|---|---|---|---|---|
| Favorites | User's favorited stations (local) | All | Horizontal carousel | Only if favorites exist |
| Recently Played | User's play history (local), excluding favorites | 10 | Horizontal carousel | Only if non-favorite history exists |
| Local Stations | User's country (auto-detected from locale, default "US") | 20 | Horizontal carousel | — |
| Top Stations | Most clicked in last 24h | 20 | Horizontal carousel | — |
| Most Voted | Most voted all time | 20 | Horizontal carousel | — |
| Recently Changed | Most recently added/changed | 10 | Vertical list | — |
| Now Playing | Most recently clicked by anyone | 10 | Vertical list | — |

Favorites and Recently Played are loaded from local storage and appear immediately, before network data loads.

- All five network sections load concurrently
- Loading spinner until data arrives; error view with retry on failure
- Previously loaded data preserved on error
- Pull-to-refresh reloads all sections
- Tapping a station plays it

---

## Search

Find stations by name with optional filters.

1. User types in search bar
2. Input debounced (400ms after last keystroke)
3. Results appear in a list, sorted by click count descending
4. Scrolling to bottom loads next page (page size: 50)

### Filters

Shown as chips below the search bar. Each can be tapped to change or clear.

| Filter | Description |
|---|---|
| Country code | ISO country code |
| Language | Language name |
| Codec | Audio codec |
| Minimum bitrate | Minimum kbps |

"Clear filters" resets all and re-searches.

### States

| Condition | Display |
|---|---|
| No query entered | "Search for radio stations" placeholder |
| Searching | Loading spinner |
| Results found | Station list |
| No results | "No stations found for '{query}'" |
| Error | Error view with retry |

---

## Browse

Browse stations organized by country, language, or tag.

### Top Level

Three navigation links: Countries, Languages, Tags.

### Category Lists

**Countries:** sorted alphabetically ascending by display name (derived from ISO code via `Locale`). Each row shows flag emoji (derived from ISO code), country display name, station count. Locally searchable. Tapping → station list for that country. Note: flag emojis do not render properly in the iOS Simulator; test on a physical device to verify flag display.

**Languages:** sorted by station count descending. Each row shows language name, station count. Tapping → station list for that language.

**Tags:** sorted by station count descending. Each row shows tag name, station count. Tapping → station list for that tag.

### Station List (shared)

Paginated list used by all three categories:
- Page size: 100
- Default sort: click count descending
- Sort picker in toolbar (segmented): "Clicks" (default) / "Name"
- Sorting is server-side via the API `order` parameter; changing sort resets pagination and re-fetches
- When sorted by name: stations are grouped into letter sections with an alphabet index on the trailing edge for quick navigation
- When sorted by clicks: flat list (no sections or index)
- Loads first page on appear
- Scroll-to-bottom loads next page
- "Has more" if last page returned exactly 100 results

---

## Favorites

User-saved stations, persisted locally.

### Actions

| Action | Behavior |
|---|---|
| Add favorite | Save locally. Auto-vote on server (mirrors RadioDroid). |
| Remove favorite | Delete from local storage. |
| Reorder | Drag-and-drop. Updates sort order on all affected entries. |
| Sync with server | Batch-fetch all favorited UUIDs from API. Update metadata. Remove favorites whose station no longer exists. |

### View

- List sorted by user-defined order
- Drag-to-reorder in edit mode
- Swipe-to-delete
- Edit button in toolbar
- Empty state: "No favorites yet"
- Pull-to-refresh triggers server sync

### Integration Points

Favorites are accessible everywhere:
- Station rows: leading swipe toggles favorite (star icon, filled when favorited)
- Full player: favorite button (star icon, orange)
- Context menu: "Add to Favorites" / "Remove from Favorites"

---

## Recent (History)

Automatic record of played stations, shown in the **Recent** tab.

- Recorded every time a station starts playing (subject to dedup/limit rules above)
- List sorted by most recent first
- Each row uses `StationRowView` with `subtitle` set to the relative timestamp ("2 hr. ago"), giving rows context menu, long-press, and swipe-to-favorite actions for free
- Tapping a row plays that station
- Toolbar button: "Clear All" (with confirmation alert)
- Empty state: clock icon + "No listening history"
- Persisted locally via UserDefaults, survives app restart

---

## Audio Playback

### Playback States

| State | Meaning |
|---|---|
| Idle | Nothing loaded |
| Loading | Stream is buffering |
| Playing | Audio is playing |
| Paused | Stream stopped (live radio — no content to resume) |
| Error | Playback failed, with message |

### Actions

| Action | Behavior |
|---|---|
| Play station | Buffer stream → start playback → update Live Activity → track click. Records `lastPlayedStation` for resume after stop. |
| Pause | Stop streaming (live radio, so pause = stop) |
| Resume | Reconnect to live stream (equivalent to re-play). Falls back to `lastPlayedStation` when `currentStation` is nil (after stop). |
| Stop | Return to idle, clear everything. `lastPlayedStation` is preserved for later resume. |
| Toggle | Pause if playing, resume if paused. From idle: replays `lastPlayedStation` if available. |

### Stream Buffering

Configures forward buffering to reduce audio interruptions on variable connections.

- Minimum forward buffer: 3 seconds (`preferredForwardBufferDuration`)
- `automaticallyWaitsToMinimizeStalling` enabled on the player
- Adaptive buffering: on each stall (buffer empty), increase buffer duration by 3 seconds, up to 15 seconds max
- Buffer config resets when switching to a different station; preserved when resuming the same station
- `stop()` resets all buffer state
- UI shows "Buffering..." in the mini player during mid-stream stalls (distinct from initial "Connecting...")

### Click Tracking

Every time a user plays a station, a click is reported to the API. Fire-and-forget — errors are silently ignored. Server enforces one click per IP per station per 24 hours.

### Voting

One vote per IP per station per 10 minutes (server-enforced). Returns success/failure message.

### Volume

Exposed as a 0.0–1.0 slider, controls player volume directly.

### System Events

| Event | Response |
|---|---|
| Phone call / Siri interruption | Pause |
| Interruption ended with "should resume" | Resume |
| Headphones disconnected | Pause |

**Implementation note:** Interruptions are observed via `AVAudioSession.interruptionNotification`. Route changes via `AVAudioSession.routeChangeNotification`, checking for `.oldDeviceUnavailable` reason. Both handlers run on `@MainActor` since `AudioPlayerService` is `@MainActor`-isolated.

### Background Audio

Playback continues when the app is backgrounded. Requires `UIBackgroundModes: audio` in Info.plist.

### HTTP Streams

Allows HTTP (non-HTTPS) for media streams only via `NSAllowsArbitraryLoadsForMedia`, not for general network traffic.

---

## Lock Screen & Control Center

### Live Activity (iOS 16.2+)

The Live Activity provides an enhanced lock screen experience. `MPNowPlayingInfoCenter.nowPlayingInfo` is also set by `updateNowPlaying()` with station name, artist metadata (country code + subdivision + codec + bitrate), live stream flag, playback rate, and favicon artwork. Live Activity takes visual priority on the lock screen; `nowPlayingInfo` provides CarPlay Now Playing tab metadata and the standard Control Center widget.

**Lock screen banner** shows:
- Station favicon (40×40 rounded rect, placeholder `antenna.radiowaves.left.and.right` icon if unavailable)
- Flag emoji + station name (headline)
- Country code + subdivision, codec, bitrate (secondary metadata, no flag emoji — emojis render as gray rectangles on the lock screen)
- Play/pause and stop buttons (iOS 17+ via `LiveActivityIntent`; static state icon on iOS 16.2)

**Dynamic Island** shows:
- Expanded: station favicon + name (leading), playback controls (trailing), country code + subdivision + codec + bitrate (bottom, no flag emoji)
- Compact: antenna icon (leading), state icon (trailing)
- Minimal: antenna icon

**Lifecycle:**
- Started on play, updated on state changes
- Ended with `.immediate` dismissal policy on stop (prevents stale banners)
- On app launch, orphaned activities from previous sessions are ended immediately
- On app restart, existing activities are recovered from `Activity<RadioActivityAttributes>.activities` before creating new ones (prevents duplicates)

**ContentState:** station name, codec, bitrate label, flag emoji, country location label (country code + subdivision), isPlaying, isLoading, isBuffering, faviconData (optional thumbnail bytes).

**Favicon in widget:** Widget extensions cannot make network requests. `LiveActivityService` fetches the favicon via `ImageCacheService` in the main app, resizes to 80×80 JPEG (~2-4KB), and passes the bytes through `ContentState.faviconData: Data?`. On station change, favicon is fetched asynchronously and the activity is re-updated when ready.

**Playback controls** (iOS 17+): `TogglePlaybackIntent` and `StopPlaybackIntent` conform to `LiveActivityIntent`. They call `RadioPlaybackAction` closures (wired to `AudioPlayerService` at launch), which run in the main app process. Shared source files in `Shared/` are compiled into both the app and widget extension targets.

### Remote Commands

Remote commands still work via `MPRemoteCommandCenter` (command routing is based on active audio session, not `nowPlayingInfo`).

| Button | Action |
|---|---|
| Play | Resume playback |
| Pause | Pause playback |
| Stop | Stop playback |
| Toggle play/pause | Toggle |
| Next track | Play next favorite |
| Previous track | Play previous favorite |

---

## Player UI

### Mini Player

Translucent floating island above the tab bar. Always visible; shows idle state ("No station playing" with antenna icon) when no station is loaded. Width is 80% of the viewport, centered.

**Visual treatment:** `.regularMaterial` background, 18pt continuous corner radius, frosted glass stroke border (0.5pt white @ 15% opacity), dual shadows (contact: 3pt/1pt, ambient: 12pt/4pt).

**Active layout** (info-left, controls-right):

| Width | Layout |
|---|---|
| Narrow (< 500pt, e.g. iPhone portrait) | `[star] [favicon + name/subtitle] [play/pause]` |
| Wide (≥ 500pt, e.g. iPhone landscape, iPad, Mac) | `[star] [favicon + name/subtitle] [prev] [play/pause] [next] [more] [volume] [AirPlay]` |

Buttons:
- **Favorite star** (orange, leading) — toggles favorite
- **Previous / Next** — skip through playback context (wide only)
- **Play/Pause** — spinner when buffering
- **More menu** (`...`) — Vote, Copy Stream URL, Share, Visit Website, Stop (wide only)
- **Volume menu** — preset levels: Mute, 25%, 50%, 75%, 100% (wide only)
- **AirPlay** — system route picker (wide only)

All buttons have 44×44pt tap targets. Subtitle shows "Connecting..." when loading, "Buffering..." during stalls, error message (red) on error, artist/track info or codec + bitrate otherwise.

Tapping anywhere (except buttons) opens the full player.

### Full Player

Sheet presented from the mini player.

Shows:
- Large favicon (120×120)
- Station name, full country name, language
- Previous / play-pause / next buttons
- Volume slider
- AirPlay button (system route picker)
- Favorite toggle (star icon, orange)
- Vote button
- Tag chips
- Station metadata: codec, bitrate, last check status + time
- Radio Browser link (opens station page at `radio-browser.info/history/{stationuuid}`)
- Homepage link (opens in Safari; percent-encodes URL for stations with special characters in their homepage)

Previous/next cycle through favorites.

---

## Station Row

Reusable list row used across all station lists.

Layout: favicon (44×44) | name + subtitle + location | codec badge + bitrate label.

Left side shows station name, subtitle line (tags by default, or custom text like relative timestamp), and location (flag emoji + country code + state/subdivision when available, e.g. "🇦🇷 AR Buenos Aires"). Right side shows codec badge and bitrate. An optional `subtitle` parameter overrides the default tags display (used by Recent tab for relative timestamps).

Interactions:
- Tap → play station
- Leading swipe → toggle favorite
- Context menu: Play, Add/Remove Favorite, Vote, Copy Stream URL, Share, Visit Website

Connecting state: When the tapped station is loading, the row dims to 60% opacity and the tag subtitle is replaced with a mini spinner + "Connecting..." label.

---

## Station Card

Compact card for horizontal carousels: favicon, name, codec/bitrate.

---

## Image Cache

Two-tier cache (memory + disk) for station favicons.

Lookup order:
1. Memory cache → return if found
2. Disk cache (`/Caches/favicons/`, filename = SHA256 of URL) → promote to memory, return
3. Download from URL → store in both tiers, return
4. On any failure → return nil (never throw)

Memory tier auto-evicts under system memory pressure. Disk tier lives in the system caches directory (may be purged by the OS under storage pressure).

### Favicon View

Reusable image view: takes an optional URL and a size. Shows an `antenna.radiowaves.left.and.right` icon placeholder while loading or on failure. Clips to rounded rectangle (corner radius = 20% of size). Reloads when URL changes.

---

## CarPlay

Browse and play stations from the car's display via `CPTemplateApplicationSceneDelegate`.

### Tabs

| Tab | Icon | Source | Limit |
|---|---|---|---|
| Favorites | star.fill | `FavoritesService.allFavorites()` | All |
| Recent | clock.fill | `HistoryService.recentEntries(limit:)` | 20 |
| Popular | chart.line.uptrend.xyaxis | `RadioBrowserService.fetchTopByClicks(limit:)` | 30 |
| Now Playing | play.fill | `CPNowPlayingTemplate.shared` (auto-populated from `MPNowPlayingInfoCenter`) | — |

### List Items

Each station list item shows:
- **Text:** station name
- **Detail text:** codec (uppercased) + bitrate (e.g. "MP3 128k"), omitting either part if unavailable
- **Image:** favicon from memory cache (sync), with async load + update; SF Symbol `antenna.radiowaves.left.and.right` as placeholder

### Playback

Tapping a list item calls `PlayerViewModel.shared.play(station:)`, which records history and triggers `NowPlayingService` — same path as the phone UI.

### Data Refresh

- On scene connect: reload all tabs
- On scene becoming active: reload all tabs
- On tab selection: reload that tab's data

No Combine observers or NotificationCenter — data sets are small and service calls are fast.

### Configuration

Requires `CPTemplateApplicationSceneSessionRoleApplication` in `UISceneConfigurations` (Info.plist) and the `com.apple.developer.carplay-audio` entitlement when code signing is enabled.

---

## Roadmap

### Completed Phases

| Phase | Name | Status |
|---|---|---|
| 1 | Foundation | Done |
| 2 | Audio Playback | Done |
| 3 | Search & Browse | Done |
| 4 | Persistence (Favorites & History) | Done |
| 5 | Player UI & Image Cache | Done |
| 6 | Polish | Done |
| 7 | Testing | Done |
| 8 | CarPlay (post-MVP) | Done |
| 9 | Live Activity (post-MVP) | Done |

### Post-MVP Features (Not Started)

#### Sleep Timer

Countdown timer that automatically stops playback after a user-selected duration. Timer UI in the full player with preset durations (15m, 30m, 60m, 90m, custom). Uses `Task.sleep` for the countdown. Timer persists across screens but not across app restarts. Shows remaining time in the mini player when active.

#### Stream Recording

Record live radio audio to files on device. Uses `AVAssetWriter` to capture audio buffers from the active stream. Recordings saved to the app's documents directory. UI to start/stop recording from the full player, with a recording indicator in the mini player. List view to browse and play back saved recordings. Metadata (station name, date, duration) stored alongside each file.

#### Track History (Song Log)

Log ICY metadata (artist + track title) parsed from streams over time. Persisted via SwiftData as `TrackHistoryEntry` records. Provides a scrollable song log per station showing what was playing and when. Optional integration with MusicBrainz or Last.fm for album art and track metadata enrichment.

#### Widgets

WidgetKit home screen widgets:
- **Now Playing widget** — shows current station name, favicon, and playback state. Tapping opens the app.
- **Favorites widget** — shows a grid or list of favorite stations. Tapping a station launches the app and starts playback.

Uses `AppIntentTimelineProvider` for widget configuration. Shared data between app and widget extension via App Group container.

#### Siri Shortcuts

`AppIntent` conformances enabling voice-activated playback:
- "Play [station name]" — searches favorites first, then API, and plays the best match.
- "Play my favorites" — starts playing the first favorite station.
- Donated intents for recently played stations so they appear as Siri suggestions.

#### Geo Search

Find stations near the user's current location using the Radio Browser geo search API (`/json/stations/search?geo_lat=&geo_long=&geo_distance=`). Requires `CoreLocation` permission. Map view showing nearby stations as pins, or list view sorted by distance. Configurable search radius.

#### M3U Export/Import

Share favorites as standard M3U playlist files with a custom `#RADIOBROWSERUUID:` extension tag for round-trip fidelity:
- **Export:** generates an M3U file from the favorites list via `FileDocument` and the system share sheet.
- **Import:** file picker accepts `.m3u` files, parses entries, and batch-lookups station UUIDs against the API to add to favorites.

#### Alarm

Wake-up alarm that starts radio playback at a scheduled time:
- Time picker with repeating day selection (weekdays, weekends, custom).
- Station picker (from favorites or search).
- Uses `UNNotificationRequest` to trigger at the scheduled time, with background audio activation to start the stream.
- Gradual volume ramp-up option.

#### Metered Connection Warning

Prompt before starting playback on a cellular or metered connection. Uses `NWPathMonitor` to detect `.constrained` path status. User can dismiss or set a "don't ask again" preference. Configurable in settings.

#### Fallback Stations

Bundled `fallback_stations.json` resource with a curated set of reliable stations. Shown on the Discover screen when the network is unavailable, ensuring the app is never completely empty on first launch without connectivity.

#### iPad Layout

Sidebar navigation with `NavigationSplitView` replacing the tab bar on iPad. Sidebar shows Discover, Recent, Search, Browse, Favorites. Detail pane shows content. Mini player spans the full width at the bottom.

#### macOS (Catalyst or native)

Menu bar player with a popover showing the mini player and quick access to favorites. Full window with sidebar navigation matching the iPad layout. Native keyboard shortcuts for playback control.
