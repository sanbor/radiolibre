# Radio Libre - iOS Internet Radio Player

## Project Overview

**Radio Libre** is a native iOS app for discovering and playing internet radio stations using the [Radio Browser](https://www.radio-browser.info/) community database (30,000+ stations). It is the iOS counterpart to [RadioDroid](https://github.com/segler-alex/RadioDroid) (Android, GPL-3.0).

- **Platform:** iOS 16+
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Audio:** AVFoundation (AVPlayer)
- **Persistence:** SwiftData (favorites, history) + UserDefaults (settings, server cache)
- **Dependencies:** None (pure Apple SDK)
- **License:** GPL-3.0

---

## Feature Set

### Core Features (MVP)

| Feature | RadioDroid Equivalent | Implementation |
|---|---|---|
| Browse top stations | Top Click / Top Vote tabs | `/json/stations/topclick`, `/json/stations/topvote` |
| Browse by country | Countries tab | `/json/countries` + `/json/stations/bycountrycodeexact/` |
| Browse by language | Languages tab | `/json/languages` + `/json/stations/bylanguageexact/` |
| Browse by tag/genre | Tags tab | `/json/tags` + `/json/stations/bytagexact/` |
| Local stations | Local tab (auto-detect country) | `Locale.current.region` + `/json/stations/bycountrycodeexact/` |
| Recently changed | Changed Lately tab | `/json/stations/lastchange/100` |
| Currently playing | Currently Playing tab | `/json/stations/lastclick/100` |
| Full-text search | Search with filters | `/json/stations/search` with name, tag, country, language, codec, bitrate filters |
| Stream playback | ExoPlayer/MediaPlayer | `AVPlayer` with HLS + progressive streams |
| Background audio | Foreground service | `AVAudioSession.playback` + `UIBackgroundModes: audio` |
| Lock screen controls | MediaSession + notification | `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter` |
| Now playing metadata | ICY metadata extraction | AVPlayer metadata observation |
| Favorites | SharedPreferences JSON | SwiftData `FavoriteStation` model |
| Favorites reordering | Drag-and-drop | SwiftUI `List` with `.onMove` |
| Play history | SharedPreferences (25 entries) | SwiftData `HistoryEntry` model (50 entries) |
| Click tracking | `/json/url/{uuid}` on play | Fire-and-forget POST on each play |
| Station voting | Vote action per station | `/json/vote/{uuid}` |
| AirPlay | N/A (Android: Chromecast) | `AVRoutePickerView` (native AirPlay button) |
| Skip next/previous | MediaSession skip commands | `MPRemoteCommandCenter` next/previous through favorites |
| Share station | Android share sheet | `ShareLink` / `UIActivityViewController` |
| Copy stream URL | Clipboard action | `UIPasteboard.general` |
| Visit station website | Open homepage | `openURL(station.homepage)` |
| Station detail | Station info dialog | Sheet with full station metadata |

### Post-MVP Features

| Feature | RadioDroid Equivalent | Implementation |
|---|---|---|
| Sleep timer | Sleep timer with countdown | `Task.sleep` + timer UI |
| Stream recording | Record to `/Music/Recordings/` | `AVAssetWriter` capturing audio buffers |
| Track history (song log) | Room DB + Last.fm art | SwiftData `TrackHistoryEntry` + MusicBrainz/Last.fm |
| Alarm | Alarm with time picker + repeating days | `UNNotificationRequest` + background audio trigger |
| Geo search | N/A | `/json/stations/search?geo_lat=&geo_long=&geo_distance=` |
| M3U export/import | M3U with `#RADIOBROWSERUUID:` | FileDocument export, file picker import |
| Equalizer | System equalizer intent | N/A (iOS has no system EQ API) |
| Server statistics | Stats view | `/json/stats` |
| CarPlay | Android Auto MediaBrowserService | `CPTemplate` integration |
| Widgets | N/A | WidgetKit for now-playing + favorites |
| Siri Shortcuts | N/A | `AppIntent` for "Play [station name]" |
| Metered connection warning | Dialog before playback on mobile | `NWPathMonitor` check for `.constrained` |
| Fallback stations | Bundled JSON resource | `fallback_stations.json` in app bundle |

---

## Radio Browser API Reference

### Server Discovery

Clients **must** discover servers dynamically (do not hardcode a single server):

1. **DNS SRV**: `_api._tcp.radio-browser.info` returns server hostnames directly
2. **DNS A/AAAA**: Resolve `all.api.radio-browser.info`, then reverse-DNS each IP
3. **Fallback**: `GET /json/servers` on any known server returns `[{ip, name}]`

Best practice: randomize server list, pick first, rotate on failure. Cache in UserDefaults with 24h TTL.

### General Rules

- **No authentication** required. No API keys.
- **User-Agent** header is mandatory: `RadioLibre/1.0 (iOS; Swift)`
- **HTTPS** preferred. All endpoints accept both GET and POST.
- **Default limit is 100,000** — always set `limit` explicitly.
- **Boolean fields** may be actual booleans or 0/1 integers depending on the field.

### Station Schema (key fields)

| Field | Type | Description |
|---|---|---|
| `stationuuid` | UUID string | Globally unique station ID |
| `name` | string | Station name (max 400 chars) |
| `url` | URL string | User-submitted stream URL |
| `url_resolved` | URL string | Auto-resolved direct stream URL (prefer this) |
| `homepage` | URL string | Station website |
| `favicon` | URL string | Station icon URL |
| `tags` | string | Comma-separated genre tags |
| `countrycode` | string | ISO 3166-1 alpha-2 (e.g. "US") |
| `country` | string | Country name (deprecated, use countrycode) |
| `state` | string | State/province |
| `language` | string | Comma-separated language names |
| `languagecodes` | string | Comma-separated ISO 639-2/B codes |
| `codec` | string | Audio codec (MP3, AAC, OGG, FLAC, etc.) |
| `bitrate` | integer | kbit/s |
| `hls` | 0 or 1 | Is HTTP Live Streaming |
| `votes` | integer | Cumulative all-time vote count |
| `clickcount` | integer | Clicks within last 24 hours |
| `clicktrend` | integer | Click diff: last 24h minus previous 24h |
| `lastcheckok` | 0 or 1 | Was online at last server check |
| `lastcheckoktime_iso8601` | ISO-8601 | Last successful health check |
| `geo_lat` / `geo_long` | double | Coordinates (nullable) |
| `has_extended_info` | boolean | Owner-provided metadata exists |
| `ssl_error` | 0 or 1 | SSL error detected |

### Common Pagination/Sorting Parameters

All list endpoints accept:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `order` | string | `"name"` | Sort by: `name`, `url`, `homepage`, `favicon`, `tags`, `country`, `state`, `language`, `votes`, `codec`, `bitrate`, `lastcheckok`, `lastchecktime`, `clicktimestamp`, `clickcount`, `clicktrend`, `changetimestamp`, `random` |
| `reverse` | boolean | `false` | Reverse sort order |
| `offset` | integer | `0` | Skip N results (pagination) |
| `limit` | integer | `100000` | Max results |
| `hidebroken` | boolean | `false` | Exclude stations where `lastcheckok=0` |

### Key Endpoints

#### Metadata Lists

| Endpoint | Response |
|---|---|
| `GET /json/countries` | `[{name, iso_3166_1, stationcount}]` |
| `GET /json/languages` | `[{name, iso_639, stationcount}]` |
| `GET /json/tags` | `[{name, stationcount}]` |
| `GET /json/codecs` | `[{name, stationcount}]` |
| `GET /json/states[/<country>]` | `[{name, country, stationcount}]` |

#### Ranked Station Lists

| Endpoint | Description |
|---|---|
| `GET /json/stations/topclick[/<count>]` | Most clicked (last 24h) |
| `GET /json/stations/topvote[/<count>]` | Most voted (all time) |
| `GET /json/stations/lastclick[/<count>]` | Most recently clicked |
| `GET /json/stations/lastchange[/<count>]` | Most recently added/changed |

#### Browse by Attribute

| Endpoint | Match |
|---|---|
| `/json/stations/byname/<term>` | Partial name match |
| `/json/stations/bynameexact/<term>` | Exact name match |
| `/json/stations/bycountrycodeexact/<code>` | Exact country code |
| `/json/stations/bylanguage/<term>` | Partial language match |
| `/json/stations/bylanguageexact/<term>` | Exact language match |
| `/json/stations/bytag/<term>` | Partial tag match |
| `/json/stations/bytagexact/<term>` | Exact tag match |
| `/json/stations/bycodec/<term>` | Partial codec match |
| `/json/stations/byuuid?uuids=<csv>` | Batch fetch by UUIDs |

#### Advanced Search

`GET/POST /json/stations/search`

| Parameter | Type | Description |
|---|---|---|
| `name` | string | Station name substring |
| `nameExact` | boolean | Exact name match |
| `country` | string | Country name |
| `countrycode` | string | ISO 3166-1 alpha-2 |
| `state` | string | State/province |
| `language` | string | Language name |
| `tag` | string | Single tag |
| `tagList` | string | Comma-separated tags (AND logic — all must match) |
| `codec` | string | Audio codec |
| `bitrateMin` | integer | Min bitrate (kbps) |
| `bitrateMax` | integer | Max bitrate (kbps) |
| `has_geo_info` | string | `"true"` / `"false"` |
| `is_https` | string | `"true"` / `"false"` |
| `geo_lat` | float | Latitude for geo search |
| `geo_long` | float | Longitude for geo search |
| `geo_distance` | float | Radius in meters |

Plus all pagination/sorting params.

#### Click Counting

`GET /json/url/<stationuuid>`

Call this every time a user plays a station. Increments click counter (one click per IP per station per 24 hours). Returns:

```json
{"ok": "true", "message": "retrieved station url", "stationuuid": "...", "name": "...", "url": "..."}
```

#### Voting

`GET/POST /json/vote/<stationuuid>`

One vote per IP per station per 10 minutes. Returns:

```json
{"ok": true, "message": "voted for station successfully"}
```

#### Server Info

| Endpoint | Returns |
|---|---|
| `GET /json/stats` | `{stations, stations_broken, tags, clicks_last_hour, clicks_last_day, languages, countries}` |
| `GET /json/servers` | `[{ip, name}]` — mirror list for fallback discovery |
| `GET /json/config` | Server operational parameters |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        Views (SwiftUI)                  │
│  RootTabView, DiscoverView, SearchView, BrowseView,     │
│  FavoritesView, HistoryView, MiniPlayerView,            │
│  FullPlayerView, StationRowView, ...                    │
├─────────────────────────────────────────────────────────┤
│                    ViewModels (@MainActor)               │
│  DiscoverVM, SearchVM, BrowseVM, StationListVM,         │
│  PlayerVM, FavoritesVM, HistoryVM                       │
├─────────────────────────────────────────────────────────┤
│                      Services (actor / @MainActor)      │
│  RadioBrowserService, ServerDiscoveryService,           │
│  AudioPlayerService, NowPlayingService,                 │
│  ImageCacheService                                      │
├─────────────────────────────────────────────────────────┤
│                     Models & Persistence                │
│  StationDTO (Codable), Country, Language, Tag           │
│  FavoriteStation (@Model), HistoryEntry (@Model)        │
│  SwiftData ModelContainer, UserDefaults                 │
├─────────────────────────────────────────────────────────┤
│                    Apple Frameworks                      │
│  AVFoundation, MediaPlayer, Network, SwiftData,         │
│  CryptoKit                                              │
└─────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

| Decision | Rationale |
|---|---|
| Separate `StationDTO` (Codable struct) from `FavoriteStation` (SwiftData @Model) | Decouples API contract from persistence schema; each evolves independently |
| `actor` for `RadioBrowserService` and `ServerDiscoveryService` | Thread-safe shared state for server rotation without manual locks |
| `@MainActor` class for `AudioPlayerService` | AVPlayer must be accessed on main thread; publishes `@Published` properties to SwiftUI |
| Task-based debounce (no Combine) | Keeps codebase Combine-free; `Task.sleep` + cancellation is idiomatic Swift concurrency |
| `@Query` in Views, mutations via ViewModels | SwiftData's `@Query` macro integrates directly with SwiftUI; ViewModel methods accept `ModelContext` for writes |
| `NSAllowsArbitraryLoadsForMedia` (not `NSAllowsArbitraryLoads`) | Targeted ATS exception — only applies to AVPlayer media URLs, not all network traffic |
| No third-party dependencies | Reduces maintenance burden; all features achievable with Apple SDK |

---

## Project Structure

```
RadioLibre/
├── RadioLibre.xcodeproj/
├── RadioLibre/
│   ├── App/
│   │   ├── RadioLibreApp.swift                 # @main, SwiftData container, environment setup
│   │   └── Info.plist                          # Background modes, ATS exceptions
│   │
│   ├── Models/
│   │   ├── StationDTO.swift                    # Codable API response model
│   │   ├── Country.swift                       # Codable: {name, iso_3166_1, stationcount}
│   │   ├── Language.swift                      # Codable: {name, iso_639, stationcount}
│   │   ├── Tag.swift                           # Codable: {name, stationcount}
│   │   ├── ClickResponse.swift                 # Codable: /json/url response
│   │   ├── VoteResponse.swift                  # Codable: /json/vote response
│   │   ├── ServerStats.swift                   # Codable: /json/stats response
│   │   ├── FavoriteStation.swift               # SwiftData @Model
│   │   ├── HistoryEntry.swift                  # SwiftData @Model
│   │   └── AppError.swift                      # Typed error enum
│   │
│   ├── Services/
│   │   ├── ServerDiscoveryService.swift         # DNS-based server discovery + rotation + caching
│   │   ├── RadioBrowserService.swift            # All API calls (actor)
│   │   ├── AudioPlayerService.swift             # AVPlayer wrapper, playback state machine
│   │   ├── NowPlayingService.swift              # MPNowPlayingInfoCenter + MPRemoteCommandCenter
│   │   └── ImageCacheService.swift              # NSCache + disk cache for favicons
│   │
│   ├── ViewModels/
│   │   ├── DiscoverViewModel.swift              # Home: top click, top vote, local stations
│   │   ├── SearchViewModel.swift                # Search with debounce + filters + pagination
│   │   ├── BrowseViewModel.swift                # Country/language/tag list loading
│   │   ├── StationListViewModel.swift           # Reusable: filtered station list + pagination
│   │   ├── PlayerViewModel.swift                # Play/pause/stop, current station, history recording
│   │   ├── FavoritesViewModel.swift             # Add/remove/reorder favorites
│   │   └── HistoryViewModel.swift               # History list, clear all, record plays
│   │
│   ├── Views/
│   │   ├── RootTabView.swift                    # TabView: Discover, Search, Browse, Favorites, History
│   │   │
│   │   ├── Discover/
│   │   │   ├── DiscoverView.swift               # Home screen: local, top click, top vote, recent, trending
│   │   │   └── StationCarouselView.swift        # Horizontal scroll row of station cards
│   │   │
│   │   ├── Search/
│   │   │   ├── SearchView.swift                 # .searchable + results list + empty/no-results states
│   │   │   └── SearchFiltersView.swift          # Filter chips: country, language, codec, min bitrate
│   │   │
│   │   ├── Browse/
│   │   │   ├── BrowseView.swift                 # Category list: Countries, Languages, Tags
│   │   │   ├── CountryListView.swift            # Countries sorted by station count, flag emoji
│   │   │   ├── LanguageListView.swift           # Languages sorted by station count
│   │   │   ├── TagListView.swift                # Tags sorted by station count
│   │   │   └── StationListView.swift            # Reusable filtered station list with pagination
│   │   │
│   │   ├── Favorites/
│   │   │   └── FavoritesView.swift              # @Query list, drag-to-reorder, swipe-to-delete
│   │   │
│   │   ├── History/
│   │   │   └── HistoryView.swift                # @Query list, relative timestamps, clear all
│   │   │
│   │   ├── Player/
│   │   │   ├── MiniPlayerView.swift             # Sticky bottom bar: favicon, name, play/pause
│   │   │   ├── FullPlayerView.swift             # Sheet: large artwork, controls, station info, tags
│   │   │   ├── PlayerControlsView.swift         # Play/pause, volume slider, AirPlay button
│   │   │   └── AirPlayButton.swift              # UIViewRepresentable wrapping AVRoutePickerView
│   │   │
│   │   ├── StationDetail/
│   │   │   └── StationDetailView.swift          # Station metadata sheet: codec, bitrate, country, homepage
│   │   │
│   │   └── Common/
│   │       ├── StationRowView.swift             # List row: favicon, name, tags, codec badge, bitrate
│   │       ├── StationCardView.swift            # Card for carousel/grid layout
│   │       ├── FaviconImageView.swift           # Async image with cache + radio icon fallback
│   │       ├── ErrorView.swift                  # Retryable error state
│   │       ├── LoadingView.swift                # Spinner placeholder
│   │       └── TagChipView.swift                # Pill-shaped tag/filter label
│   │
│   ├── Extensions/
│   │   ├── String+CountryFlag.swift             # ISO country code -> flag emoji via Unicode scalars
│   │   └── URL+RadioBrowser.swift               # URL construction helpers
│   │
│   └── Resources/
│       ├── Assets.xcassets/
│       │   ├── AppIcon.appiconset/
│       │   ├── AccentColor.colorset/
│       │   └── Colors/
│       └── Localizable.xcstrings                # All user-facing strings
│
└── RadioLibreTests/
    ├── Services/
    │   ├── RadioBrowserServiceTests.swift
    │   ├── ServerDiscoveryServiceTests.swift
    │   └── AudioPlayerServiceTests.swift
    └── ViewModels/
        ├── SearchViewModelTests.swift
        ├── DiscoverViewModelTests.swift
        └── FavoritesViewModelTests.swift
```

---

## Detailed Component Specifications

### Models

#### `StationDTO.swift`

```swift
struct StationDTO: Codable, Identifiable, Hashable {
    var id: String { stationuuid }

    let stationuuid: String
    let name: String
    let url: String
    let urlResolved: String?       // CodingKey: url_resolved
    let homepage: String?
    let favicon: String?
    let tags: String?              // comma-separated
    let country: String?
    let countrycode: String?
    let state: String?
    let language: String?
    let languagecodes: String?
    let codec: String?
    let bitrate: Int?
    let hls: Int?                  // 0 or 1
    let votes: Int?
    let clickcount: Int?
    let clicktrend: Int?
    let lastcheckok: Int?          // 0 or 1
    let lastcheckoktime: String?
    let lastcheckoktime_iso8601: String?  // kept as-is, not snake_case converted
    let geoLat: Double?            // CodingKey: geo_lat
    let geoLong: Double?           // CodingKey: geo_long
    let hasExtendedInfo: Bool?     // CodingKey: has_extended_info

    // Computed helpers
    var tagList: [String]          // split tags by comma, trim whitespace
    var isHLS: Bool                // hls == 1
    var isOnline: Bool             // lastcheckok == 1
    var streamURL: URL?            // URL(string: urlResolved ?? url)
    var faviconURL: URL?           // URL(string: favicon ?? "")
    var homepageURL: URL?          // URL(string: homepage ?? "")
    var bitrateLabel: String       // e.g. "128k" or "—"
}
```

Use explicit `CodingKeys` enum (the API uses `snake_case` and some inconsistent naming like `url_resolved`).

#### `FavoriteStation.swift`

```swift
@Model
final class FavoriteStation {
    @Attribute(.unique) var stationuuid: String
    var name: String
    var urlResolved: String
    var faviconURL: String?
    var tags: String?
    var countrycode: String?
    var language: String?
    var codec: String?
    var bitrate: Int
    var addedAt: Date
    var sortOrder: Int             // for manual reordering

    init(from dto: StationDTO) { ... }
    func toDTO() -> StationDTO { ... }
}
```

#### `HistoryEntry.swift`

```swift
@Model
final class HistoryEntry {
    @Attribute(.unique) var id: UUID
    var stationuuid: String
    var name: String
    var urlResolved: String
    var faviconURL: String?
    var codec: String?
    var bitrate: Int
    var countrycode: String?
    var playedAt: Date

    init(from dto: StationDTO) { ... }
    func toDTO() -> StationDTO { ... }
}
```

Max 50 entries. On insert, if same `stationuuid` played within 30 minutes, update `playedAt` instead of inserting (prevents flooding on network reconnects).

#### `AppError.swift`

```swift
enum AppError: LocalizedError {
    case networkUnavailable
    case serverDiscoveryFailed
    case serverError(statusCode: Int)
    case decodingFailed(underlying: Error)
    case streamURLInvalid
    case audioSessionFailed(underlying: Error)
    case playbackFailed(underlying: Error)
    case noServersAvailable

    var errorDescription: String? { ... }
    var recoverySuggestion: String? { ... }
}
```

---

### Services

#### `ServerDiscoveryService.swift`

```swift
actor ServerDiscoveryService {
    static let shared = ServerDiscoveryService()

    private var servers: [String] = []
    private var currentIndex: Int = 0
    private var lastResolved: Date?
    private let ttl: TimeInterval = 86400  // 24 hours

    // Public API
    var currentBaseURL: URL { get }
    func resolveIfNeeded() async
    func rotateServer()

    // DNS resolution
    // Use getaddrinfo() in Task.detached + getnameinfo() for reverse DNS
    // Or use Network.framework NWEndpoint for modern approach
    // Cache results in UserDefaults: ["radio_browser_servers": [String], "radio_browser_servers_ts": Date]
    // Shuffle on each resolution for load balancing
}
```

#### `RadioBrowserService.swift`

```swift
actor RadioBrowserService {
    static let shared = RadioBrowserService()

    private let session: URLSession  // custom User-Agent: "RadioLibre/1.0 (iOS; Swift)"
    private let decoder: JSONDecoder // with snake_case key decoding strategy
    private let discovery: ServerDiscoveryService

    // --- Discovery ---
    func fetchTopByClicks(limit: Int = 100) async throws -> [StationDTO]
    func fetchTopByVotes(limit: Int = 100) async throws -> [StationDTO]
    func fetchLastClick(limit: Int = 100) async throws -> [StationDTO]
    func fetchLastChange(limit: Int = 100) async throws -> [StationDTO]
    func fetchLocalStations(countrycode: String, limit: Int = 100) async throws -> [StationDTO]

    // --- Search ---
    func searchStations(
        name: String? = nil,
        countrycode: String? = nil,
        country: String? = nil,
        language: String? = nil,
        tag: String? = nil,
        tagList: String? = nil,       // comma-separated, AND logic
        codec: String? = nil,
        bitrateMin: Int? = nil,
        bitrateMax: Int? = nil,
        isHttps: Bool? = nil,
        order: String = "clickcount",
        reverse: Bool = true,
        limit: Int = 50,
        offset: Int = 0,
        hidebroken: Bool = true
    ) async throws -> [StationDTO]

    // --- Browse ---
    func fetchCountries(hidebroken: Bool = true) async throws -> [Country]
    func fetchLanguages(hidebroken: Bool = true) async throws -> [Language]
    func fetchTags(limit: Int = 200, hidebroken: Bool = true, order: String = "stationcount", reverse: Bool = true) async throws -> [Tag]

    // --- Filtered lists ---
    func fetchStationsByCountry(_ countrycode: String, order: String = "clickcount", reverse: Bool = true, limit: Int = 100, offset: Int = 0) async throws -> [StationDTO]
    func fetchStationsByLanguage(_ language: String, ...) async throws -> [StationDTO]
    func fetchStationsByTag(_ tag: String, ...) async throws -> [StationDTO]

    // --- Station lookup ---
    func fetchStation(uuid: String) async throws -> StationDTO
    func fetchStations(uuids: [String]) async throws -> [StationDTO]

    // --- Analytics (fire-and-forget) ---
    func trackClick(stationuuid: String) async   // POST /json/url/{uuid}
    func vote(stationuuid: String) async throws -> VoteResponse  // POST /json/vote/{uuid}

    // --- Server info ---
    func fetchStats() async throws -> ServerStats

    // --- Internal ---
    // On request failure: call discovery.rotateServer(), retry once
    // URL construction via URLComponents
    // All endpoints: https://{server}/json/{path}?{params}
}
```

#### `AudioPlayerService.swift`

```swift
@MainActor
final class AudioPlayerService: ObservableObject {
    static let shared = AudioPlayerService()

    // --- Published state ---
    @Published private(set) var state: PlaybackState = .idle
    @Published var volume: Float = 1.0  // bound to AVPlayer.volume

    enum PlaybackState: Equatable {
        case idle
        case loading(station: StationDTO)
        case playing(station: StationDTO)
        case paused(station: StationDTO)    // for radio = stopped stream
        case error(station: StationDTO, message: String)
    }

    // Computed
    var currentStation: StationDTO? { ... }
    var isPlaying: Bool { ... }
    var isLoading: Bool { ... }

    // --- Public API ---
    func play(station: StationDTO)
    func pause()                          // stops stream (radio is live)
    func resume()                         // reconnects to stream
    func stop()                           // returns to .idle
    func togglePlayPause()

    // --- Internal ---
    private let player = AVPlayer()
    private var playerItemObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private let nowPlayingService = NowPlayingService.shared

    // Setup:
    // 1. AVAudioSession.sharedInstance().setCategory(.playback, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
    // 2. AVAudioSession.sharedInstance().setActive(true)
    // 3. Observe AVAudioSession.interruptionNotification (phone calls, Siri)
    // 4. Observe AVAudioSession.routeChangeNotification (headphone disconnect → pause)
    // 5. KVO on player.timeControlStatus → update state (.waitingToPlayAtSpecifiedRate = loading, .playing = playing, .paused = paused)
    // 6. KVO on player.currentItem?.status → detect errors

    // play(station:) flow:
    // 1. Set state = .loading(station)
    // 2. Create AVURLAsset(url: station.streamURL)
    // 3. Create AVPlayerItem(asset:)
    // 4. player.replaceCurrentItem(with:)
    // 5. player.play()
    // 6. Update NowPlayingService
    // 7. Track click via RadioBrowserService.trackClick (fire-and-forget)
}
```

**Audio session interruption handling:**

```swift
// Began: pause playback
// Ended with .shouldResume: resume playback
```

**Route change handling:**

```swift
// .oldDeviceUnavailable (headphone disconnect): pause playback
```

#### `NowPlayingService.swift`

```swift
@MainActor
final class NowPlayingService {
    static let shared = NowPlayingService()

    // Setup (called once at init):
    // Register MPRemoteCommandCenter handlers:
    //   - playCommand → audioService.resume()
    //   - pauseCommand → audioService.pause()
    //   - stopCommand → audioService.stop()
    //   - togglePlayPauseCommand → audioService.togglePlayPause()
    //   - nextTrackCommand → play next favorite (optional)
    //   - previousTrackCommand → play previous favorite (optional)

    func updateNowPlaying(station: StationDTO, isPlaying: Bool)
    // Sets MPNowPlayingInfoCenter.default().nowPlayingInfo:
    //   MPMediaItemPropertyTitle: station.name
    //   MPMediaItemPropertyArtist: station.country ?? ""
    //   MPMediaItemPropertyAlbumTitle: station.tagList.prefix(3).joined(separator: ", ")
    //   MPNowPlayingInfoPropertyIsLiveStream: true   // hides seek bar
    //   MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
    //   MPMediaItemPropertyArtwork: fetched async from station.favicon

    func clearNowPlaying()
}
```

**Important:** Set `MPNowPlayingInfoPropertyIsLiveStream: true` to prevent the seek bar from appearing on the lock screen.

#### `ImageCacheService.swift`

```swift
actor ImageCacheService {
    static let shared = ImageCacheService()

    private let memoryCache = NSCache<NSString, UIImage>()  // auto-evicts under memory pressure
    private let diskCacheDirectory: URL  // FileManager.cachesDirectory/favicons/

    func image(for url: URL) async -> UIImage?
    // 1. Check NSCache (memory)
    // 2. Check disk cache (SHA256 of URL string as filename, via CryptoKit)
    // 3. Download via URLSession.shared.data(from:)
    // 4. Store in both caches
    // 5. Return UIImage or nil
}
```

---

### ViewModels

#### `DiscoverViewModel.swift`

```swift
@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var localStations: [StationDTO] = []
    @Published var topByClicks: [StationDTO] = []
    @Published var topByVotes: [StationDTO] = []
    @Published var recentlyChanged: [StationDTO] = []
    @Published var currentlyPlaying: [StationDTO] = []
    @Published var isLoading = false
    @Published var error: AppError?

    func load() async
    // Uses async let for concurrent fetches:
    //   localCountry = Locale.current.region?.identifier ?? "US"
    //   async let local = service.fetchLocalStations(countrycode: localCountry, limit: 20)
    //   async let clicks = service.fetchTopByClicks(limit: 20)
    //   async let votes = service.fetchTopByVotes(limit: 20)
    //   async let changed = service.fetchLastChange(limit: 20)
    //   async let playing = service.fetchLastClick(limit: 20)

    func refresh() async
}
```

#### `SearchViewModel.swift`

```swift
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = "" { didSet { onQueryChanged() } }
    @Published var results: [StationDTO] = []
    @Published var isSearching = false
    @Published var hasSearched = false
    @Published var error: AppError?

    // Filters
    @Published var filterCountrycode: String?
    @Published var filterLanguage: String?
    @Published var filterCodec: String?
    @Published var filterBitrateMin: Int?

    // Pagination
    private var currentOffset = 0
    private let pageSize = 50
    @Published var hasMore = true

    private var searchTask: Task<Void, Never>?

    func onQueryChanged()
    // Cancel previous task, debounce 400ms via Task.sleep, then performSearch()

    func performSearch() async
    // Calls RadioBrowserService.searchStations with all filters
    // Sets hasSearched = true, resets offset

    func loadMore() async
    // Increments offset, appends results, sets hasMore = results.count == pageSize

    func clearFilters()
}
```

#### `BrowseViewModel.swift`

```swift
@MainActor
final class BrowseViewModel: ObservableObject {
    @Published var countries: [Country] = []
    @Published var languages: [Language] = []
    @Published var tags: [Tag] = []
    @Published var isLoading = false
    @Published var error: AppError?

    func loadCountries() async
    func loadLanguages() async
    func loadTags() async
}
```

#### `StationListViewModel.swift`

```swift
@MainActor
final class StationListViewModel: ObservableObject {
    enum Filter {
        case country(String)
        case language(String)
        case tag(String)
    }

    let filter: Filter
    let title: String

    @Published var stations: [StationDTO] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: AppError?
    @Published var hasMore = true

    private var currentOffset = 0
    private let pageSize = 100

    init(filter: Filter) { ... }

    func load() async       // first page
    func loadMore() async   // append next page, guard concurrent calls
}
```

#### `PlayerViewModel.swift`

```swift
@MainActor
final class PlayerViewModel: ObservableObject {
    let audioService: AudioPlayerService

    // Computed from audioService.state
    var currentStation: StationDTO? { ... }
    var isPlaying: Bool { ... }
    var isLoading: Bool { ... }
    var errorMessage: String? { ... }

    func play(station: StationDTO, context: ModelContext)
    // 1. audioService.play(station:)
    // 2. Record in history: insert or update HistoryEntry (30min dedup window)
    // 3. Enforce 50-entry history limit

    func togglePlayPause()
    func stop()

    func vote(station: StationDTO) async throws -> VoteResponse
}
```

#### `FavoritesViewModel.swift`

```swift
@MainActor
final class FavoritesViewModel: ObservableObject {
    func addFavorite(station: StationDTO, context: ModelContext)
    // Also fires RadioBrowserService.vote() (RadioDroid auto-votes on favorite)

    func removeFavorite(uuid: String, context: ModelContext)
    func isFavorite(uuid: String, context: ModelContext) -> Bool
    func moveFavorites(from: IndexSet, to: Int, context: ModelContext)
    // Update sortOrder on all affected FavoriteStation entries

    func syncWithServer(favorites: [FavoriteStation], context: ModelContext) async
    // Batch fetch by UUIDs via RadioBrowserService.fetchStations(uuids:)
    // Remove any favorites whose stationuuid is no longer in the API (station deleted)
}
```

---

### Views

#### `RootTabView.swift`

```swift
TabView {
    DiscoverView()       // .tabItem { Label("Discover", systemImage: "antenna.radiowaves.left.and.right") }
    SearchView()         // .tabItem { Label("Search", systemImage: "magnifyingglass") }
    BrowseView()         // .tabItem { Label("Browse", systemImage: "list.bullet") }
    FavoritesView()      // .tabItem { Label("Favorites", systemImage: "heart.fill") }
    HistoryView()        // .tabItem { Label("History", systemImage: "clock") }
}
.safeAreaInset(edge: .bottom) {
    if playerVM.currentStation != nil {
        MiniPlayerView()
            .background(.ultraThinMaterial)
    }
}
```

Each tab wraps content in `NavigationStack`.

#### `DiscoverView.swift`

ScrollView with sections:
1. **"Local Stations"** — horizontal carousel of `StationCardView` (auto-detected country)
2. **"Top Stations"** — horizontal carousel (by clicks)
3. **"Most Voted"** — horizontal carousel (by votes)
4. **"Recently Changed"** — vertical list of `StationRowView` (limited to 10)
5. **"Now Playing"** — vertical list of `StationRowView` (limited to 10)

Pull-to-refresh via `.refreshable`. Error state with retry button.

#### `SearchView.swift`

- `.searchable(text: $vm.query)` on NavigationStack for system search bar
- Results in `List` with `StationRowView` rows
- Empty state: "Search for radio stations"
- No results state: "No stations found for '{query}'"
- Below search bar: horizontal `ScrollView` of filter chips (country, language, codec, bitrate)
- Pagination: `.onAppear` on last row triggers `loadMore()`

#### `BrowseView.swift`

`List` with three `NavigationLink` sections:
- "Countries" → `CountryListView`
- "Languages" → `LanguageListView`
- "Tags" → `TagListView`

Each loads lazily on appear.

#### `CountryListView.swift`

`List` of countries sorted by `stationcount` descending. Each row:
- Flag emoji (ISO code → Unicode regional indicator: `code.unicodeScalars.compactMap { Unicode.Scalar(127397 + $0.value) }`)
- Country name
- Station count badge

Tapping → `StationListView(filter: .country(country.iso_3166_1))`.

Search bar for filtering the country list locally.

#### `StationRowView.swift`

```
┌──────────────────────────────────────────────────┐
│ [favicon]  Station Name                  MP3     │
│   44x44    rock, jazz, classic          128k     │
└──────────────────────────────────────────────────┘
```

- Swipe actions: leading = toggle favorite (heart icon)
- Context menu: Play, Add to Favorites, Vote, Copy Stream URL, Share, Visit Website
- Tapping plays the station

#### `MiniPlayerView.swift`

Persistent bottom bar above tab bar (via `safeAreaInset`):

```
┌──────────────────────────────────────────────────┐
│ [icon] Station Name          [⏸] [⏹]            │
│  40x40  MP3 · 128kbps                           │
└──────────────────────────────────────────────────┘
```

- Tap anywhere (except buttons) → present `FullPlayerView` as sheet
- Shows loading spinner when buffering

#### `FullPlayerView.swift`

Full-screen sheet:

```
┌──────────────────────────────────────────────────┐
│                 ── drag handle ──                 │
│                                                  │
│              ┌──────────────────┐                │
│              │                  │                │
│              │    [favicon]     │                │
│              │    120x120       │                │
│              │                  │                │
│              └──────────────────┘                │
│                                                  │
│              Station Name                        │
│              Country · Language                  │
│                                                  │
│         [⏮]    [⏯ large]    [⏭]                 │
│                                                  │
│        🔈 ━━━━━━━━━━━━━━━━━ 🔊   [AirPlay]      │
│                                                  │
│         [♡ Favorite]    [⬆ Vote]                 │
│                                                  │
│         ┌─rock─┐ ┌─jazz─┐ ┌─blues─┐             │
│                                                  │
│         Codec: MP3  ·  Bitrate: 128 kbps         │
│         Last checked: 2 hours ago ✅              │
│         Website: station.example.com →           │
│                                                  │
└──────────────────────────────────────────────────┘
```

#### `AirPlayButton.swift`

```swift
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = .label
        return picker
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
```

#### `FaviconImageView.swift`

```swift
struct FaviconImageView: View {
    let urlString: String?
    let size: CGFloat

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "radio").resizable().foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
        .task(id: urlString) {
            guard let urlString, let url = URL(string: urlString) else { return }
            image = await ImageCacheService.shared.image(for: url)
        }
    }
}
```

---

### App Entry Point

#### `RadioLibreApp.swift`

```swift
@main
struct RadioLibreApp: App {
    @StateObject private var playerVM = PlayerViewModel(audioService: .shared)
    @StateObject private var favoritesVM = FavoritesViewModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(playerVM)
                .environmentObject(favoritesVM)
                .modelContainer(for: [FavoriteStation.self, HistoryEntry.self])
                .task { await ServerDiscoveryService.shared.resolveIfNeeded() }
        }
    }
}
```

#### `Info.plist` Required Entries

```xml
<!-- Background audio mode -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>

<!-- ATS exception for radio streams (many use HTTP) -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoadsForMedia</key>
    <true/>
</dict>
```

`NSAllowsArbitraryLoadsForMedia` only relaxes ATS for media loaded by AVFoundation, not for all network traffic. This is more targeted than `NSAllowsArbitraryLoads`.

---

## iOS-Specific Technical Considerations

### Background Audio
- `UIBackgroundModes: audio` in Info.plist (mandatory)
- `AVAudioSession.category = .playback` (not `.ambient` or `.soloAmbient`)
- `AVAudioSession.setActive(true)` before first playback
- AVPlayer continues automatically in background once session is configured

### Lock Screen & Control Center
- `MPRemoteCommandCenter` handlers registered once at app start
- Commands: `playCommand`, `pauseCommand`, `stopCommand`, `togglePlayPauseCommand`, `nextTrackCommand`, `previousTrackCommand`
- `MPNowPlayingInfoCenter` updated on every state change
- `MPNowPlayingInfoPropertyIsLiveStream = true` prevents scrubber
- Artwork loaded async — update nowPlayingInfo without artwork first, then again with artwork

### AirPlay
- `AVRoutePickerView` (UIKit, wrapped in UIViewRepresentable) provides native AirPlay button
- `.allowAirPlay` on AVAudioSession enables routing
- No custom code needed — AVPlayer handles AirPlay 2 natively

### Audio Session Interruptions
- **Phone call / Siri begins:** pause playback
- **Interruption ends with `.shouldResume`:** resume playback
- Observed via `AVAudioSession.interruptionNotification`

### Route Changes
- **Headphone disconnect (`.oldDeviceUnavailable`):** pause playback (standard iOS behavior)
- Observed via `AVAudioSession.routeChangeNotification`

### Network Monitoring
- `NWPathMonitor` from `Network.framework` for connectivity detection
- Show offline indicator when `path.status != .satisfied`
- Detect metered connections via `path.isConstrained` (optional: warn before playback on cellular)

### Concurrency Model
- ViewModels: `@MainActor` classes with `@Published` properties
- `RadioBrowserService`, `ServerDiscoveryService`, `ImageCacheService`: `actor` (thread-safe)
- `AudioPlayerService`: `@MainActor` class (AVPlayer requires main thread)
- No Combine — Swift structured concurrency throughout

### Memory Management
- `NSCache` for image cache (auto-evicts under pressure)
- `AVPlayerItem` KVO observations stored as `NSKeyValueObservation` tokens, cancelled in service methods
- SwiftData `@Query` with appropriate `FetchDescriptor` limits

---

## Implementation Phases

### Phase 1: Foundation
**Goal:** App builds, discovers servers, fetches and displays stations.

1. Create Xcode project (RadioLibre, iOS 16+, SwiftUI, SwiftData)
2. Configure `Info.plist`: `UIBackgroundModes: audio`, `NSAllowsArbitraryLoadsForMedia`
3. `AppError.swift`
4. `StationDTO.swift` with CodingKeys and computed properties
5. `Country.swift`, `Language.swift`, `Tag.swift`
6. `ClickResponse.swift`, `VoteResponse.swift`
7. `ServerDiscoveryService.swift` with DNS resolution + UserDefaults cache
8. `RadioBrowserService.swift` with `fetchTopByClicks`, `fetchTopByVotes`, `trackClick`
9. `DiscoverViewModel.swift` (top clicks + top votes only)
10. `StationRowView.swift` (basic, no swipe actions yet)
11. `DiscoverView.swift` (vertical lists, no carousel yet)
12. `RootTabView.swift` with Discover tab only
13. `RadioLibreApp.swift` with server discovery on launch

**Verify:** App launches, resolves API server, fetches top stations, displays them in a list.

### Phase 2: Audio Playback
**Goal:** Tap a station → it plays. Background audio and lock screen controls work.

1. `AudioPlayerService.swift`: AVAudioSession setup, AVPlayer, state machine, KVO
2. `NowPlayingService.swift`: MPNowPlayingInfoCenter, MPRemoteCommandCenter
3. `PlayerViewModel.swift`
4. `MiniPlayerView.swift` (basic: name + play/pause)
5. Wire MiniPlayerView into RootTabView via `safeAreaInset`
6. Wire StationRowView tap → playerVM.play()
7. Test background audio (backgrounding app)
8. Test lock screen controls (play/pause/stop)
9. Test interruptions (simulate phone call)
10. Test route change (disconnect headphones)

**Verify:** Can play any station, audio continues in background, lock screen shows station name and controls.

### Phase 3: Search & Browse
**Goal:** Full station discovery through search, browse by category, and drill-down lists.

1. `SearchViewModel.swift` with debounce and pagination
2. `SearchView.swift` with `.searchable` and results list
3. `BrowseViewModel.swift`
4. `BrowseView.swift` with category navigation
5. `CountryListView.swift` with flag emoji and station counts
6. `LanguageListView.swift`
7. `TagListView.swift`
8. `StationListViewModel.swift` with pagination
9. `StationListView.swift` (reusable filtered list)
10. `String+CountryFlag.swift` extension
11. Wire all tabs in RootTabView

**Verify:** Can search by name, browse countries/languages/tags, drill into station lists with pagination.

### Phase 4: Persistence
**Goal:** Favorites and history persist across app restarts.

1. `FavoriteStation.swift` SwiftData model
2. `HistoryEntry.swift` SwiftData model
3. Configure `modelContainer` in RadioLibreApp
4. `FavoritesViewModel.swift` (add/remove/reorder/sync)
5. `FavoritesView.swift` with `@Query`, drag-to-reorder, swipe-to-delete
6. `HistoryViewModel.swift` (record plays, clear all, enforce limit)
7. `HistoryView.swift` with `@Query`, relative timestamps
8. Add swipe-to-favorite on `StationRowView`
9. Add favorite heart button to `FullPlayerView`
10. Record history entries in `PlayerViewModel.play()`
11. Auto-vote on favorite (RadioDroid behavior)

**Verify:** Favorites persist, can reorder, history accumulates with deduplication, survives app kill.

### Phase 5: Player UI & Image Cache
**Goal:** Full player sheet, AirPlay, station detail, favicon caching.

1. `ImageCacheService.swift` (NSCache + disk)
2. `FaviconImageView.swift` (async load with fallback)
3. Update `StationRowView` to use FaviconImageView
4. `FullPlayerView.swift` with large artwork, station info, tags
5. `PlayerControlsView.swift` with play/pause, volume, AirPlay
6. `AirPlayButton.swift` (AVRoutePickerView wrapper)
7. `StationDetailView.swift` (metadata sheet)
8. `StationCardView.swift` for carousel
9. `StationCarouselView.swift`
10. Update `DiscoverView` to use carousel layout
11. `SearchFiltersView.swift` with filter chips
12. Update MiniPlayerView with favicon and loading spinner
13. Update NowPlayingService to fetch and display favicon as artwork

**Verify:** Full player sheet works, AirPlay button shows system picker, favicons load and cache, carousel scrolls smoothly.

### Phase 6: Polish
**Goal:** Production-quality UX, error handling, accessibility.

1. `ErrorView.swift` and `LoadingView.swift` used throughout
2. `TagChipView.swift` for tag display
3. Context menus on StationRowView (Play, Favorite, Vote, Copy URL, Share, Website)
4. Vote functionality (button in FullPlayerView, context menu)
5. `NWPathMonitor` network observation + offline indicators
6. Station count / last check badges
7. Next/previous track via favorites in MPRemoteCommandCenter
8. `FavoritesViewModel.syncWithServer()` (detect deleted stations)
9. Accessibility labels and VoiceOver support
10. Dynamic Type support (relative font sizes)
11. `Localizable.xcstrings` for all user-facing strings
12. App icon design + AccentColor
13. SwiftData `VersionedSchema` for migration readiness
14. `ServerStats.swift` model + optional stats view
15. Performance profiling with Instruments

### Phase 7: Testing
**Goal:** Automated test coverage for services and view models.

1. Mock `URLSession` via protocol for service tests
2. `ServerDiscoveryServiceTests.swift` (resolution, rotation, caching)
3. `RadioBrowserServiceTests.swift` (endpoint URL construction, decoding, error handling)
4. `AudioPlayerServiceTests.swift` (state transitions)
5. `SearchViewModelTests.swift` (debounce, pagination, filters)
6. `DiscoverViewModelTests.swift` (concurrent loading)
7. `FavoritesViewModelTests.swift` (add/remove/reorder/sync)
8. UI tests for critical flows: search → play, browse → play, favorite toggle
9. Physical device testing: background audio, AirPlay, interruptions

---

## Post-MVP Roadmap

These features can be added after the core app is stable:

1. **Sleep Timer** — countdown timer that stops playback
2. **Stream Recording** — capture audio to file using `AVAssetWriter`
3. **Track History** — display ICY metadata (artist/track) from stream
4. **CarPlay** — `CPTemplate`-based interface for in-car use
5. **Widgets** — WidgetKit for now-playing and favorite stations
6. **Siri Shortcuts** — `AppIntent` for "Play [station name]"
7. **Geo Search** — find stations near current location
8. **M3U Export/Import** — share favorites as playlist files
9. **iPad Layout** — sidebar navigation with split view
10. **macOS (Catalyst/native)** — menu bar player
