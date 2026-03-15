# RadioLibre

Native iOS internet radio player powered by the [Radio Browser](https://www.radio-browser.info/) community database (30,000+ stations). iOS counterpart to [RadioDroid](https://github.com/segler-alex/RadioDroid) (Android).

- iOS 16+, SwiftUI, no third-party dependencies
- License: GPL-3.0

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
| Discover | antenna.radiowaves.left.and.right | Home with curated sections |
| Recent | clock | Recently played stations |
| Search | magnifyingglass | Search with filters |
| Browse | list.bullet | Countries / Languages / Tags |
| Favorites | heart.fill | Saved stations |

A mini player bar sits above the tab bar whenever a station is loaded.

---

## Discover (Home)

Shows curated station sections at a glance.

| Section | Source | Limit | Layout | Condition |
|---|---|---|---|---|
| Favorites | User's favorited stations (local) | All | Horizontal carousel | Only if favorites exist |
| Recently Played | User's play history (local) | 10 | Horizontal carousel | Only if history exists |
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
- Station rows: leading swipe toggles favorite (heart icon, filled when favorited)
- Full player: favorite button
- Context menu: "Add to Favorites" / "Remove from Favorites"

---

## Recent (History)

Automatic record of played stations, shown in the **Recent** tab.

- Recorded every time a station starts playing (subject to dedup/limit rules above)
- List sorted by most recent first
- Each row shows station info + relative timestamp ("2 hr. ago")
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
| Play station | Buffer stream → start playback → update now-playing → track click |
| Pause | Stop streaming (live radio, so pause = stop) |
| Resume | Reconnect to live stream (equivalent to re-play) |
| Stop | Return to idle, clear everything |
| Toggle | Pause if playing, resume if paused |

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

## Now Playing (Lock Screen & Control Center)

When a station is playing, display:
- **Title:** station name
- **Artist:** flag emoji + country name (e.g. "🇫🇷 France")
- **Album:** first 3 tags, comma-separated
- **Live stream:** yes (hides seek bar)
- **Playback rate:** 1.0 when playing, 0.0 when paused
- **Artwork:** station favicon, loaded asynchronously (display info immediately, update artwork when loaded)

When playback stops, clear all info.

### Remote Commands

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

Persistent bar above the tab bar. Always visible; shows idle state when no station is loaded.

Shows: favicon (40×40), station name, codec + bitrate, play/pause button, stop button. Spinner replaces play/pause button when buffering. Subtitle shows "Connecting..." when loading, error message (in red) on error, codec + bitrate otherwise. Translucent background.

Tapping anywhere (except buttons) opens the full player.

### Full Player

Sheet presented from the mini player.

Shows:
- Large favicon (120×120)
- Station name, country, language
- Previous / play-pause / next buttons
- Volume slider
- AirPlay button (system route picker)
- Favorite toggle (heart icon)
- Vote button
- Tag chips
- Station metadata: codec, bitrate, last check status + time
- Homepage link (opens in Safari)

Previous/next cycle through favorites.

---

## Station Row

Reusable list row used across all station lists.

Layout: favicon (44×44) | name + tags (up to 3) | codec badge + bitrate label.

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

Reusable image view: takes an optional URL and a size. Shows a radio icon placeholder while loading or on failure. Clips to rounded rectangle (corner radius = 20% of size). Reloads when URL changes.

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
- **Image:** favicon from memory cache (sync), with async load + update; SF Symbol `radio` as placeholder

### Playback

Tapping a list item calls `PlayerViewModel.shared.play(station:)`, which records history and triggers `NowPlayingService` — same path as the phone UI.

### Data Refresh

- On scene connect: reload all tabs
- On scene becoming active: reload all tabs
- On tab selection: reload that tab's data

No Combine observers or NotificationCenter — data sets are small and service calls are fast.

### Configuration

Requires `CPTemplateApplicationSceneSessionRoleApplication` in `UISceneConfigurations` (Info.plist) and the `com.apple.developer.carplay-audio` entitlement when code signing is enabled.
