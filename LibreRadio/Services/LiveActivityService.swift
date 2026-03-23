import ActivityKit
import Foundation
import UIKit

@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    private static let staleInterval: TimeInterval = 15 * 60

    private var currentActivity: (any AnyLiveActivity)?
    private var currentFaviconData: Data?
    private var currentStationId: String?
    private var lastStation: StationDTO?
    private var lastIsPlaying = false
    private var lastIsLoading = false
    private var lastIsBuffering = false

    private init() {}

    func startOrUpdate(station: StationDTO, isPlaying: Bool, isLoading: Bool, isBuffering: Bool) {
        guard #available(iOS 16.2, *) else { return }

        lastStation = station
        lastIsPlaying = isPlaying
        lastIsLoading = isLoading
        lastIsBuffering = isBuffering

        if station.stationuuid != currentStationId {
            currentStationId = station.stationuuid
            currentFaviconData = nil
            fetchFavicon(for: station)
        }

        performUpdate()
    }

    func end() {
        guard #available(iOS 16.2, *) else { return }

        if let activity = currentActivity as? Activity<RadioActivityAttributes> {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        } else {
            for activity in Activity<RadioActivityAttributes>.activities {
                Task {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
        currentActivity = nil
        currentFaviconData = nil
        currentStationId = nil
        lastStation = nil
    }

    func endOrphanedActivities() {
        guard #available(iOS 16.2, *) else { return }

        Task {
            for activity in Activity<RadioActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: - Private

    private func fetchFavicon(for station: StationDTO) {
        guard let url = station.faviconURL else { return }
        let stationId = station.stationuuid

        Task {
            guard let image = await ImageCacheService.shared.image(for: url) else { return }

            let size = CGSize(width: 80, height: 80)
            let renderer = UIGraphicsImageRenderer(size: size)
            let resized = renderer.jpegData(withCompressionQuality: 0.7) { context in
                image.draw(in: CGRect(origin: .zero, size: size))
            }

            // Only apply if we're still on the same station
            guard currentStationId == stationId else { return }
            currentFaviconData = resized
            performUpdate()
        }
    }

    private func performUpdate() {
        guard #available(iOS 16.2, *), let station = lastStation else { return }

        let state = RadioActivityAttributes.ContentState(
            stationName: station.name,
            codec: station.codec,
            bitrateLabel: station.bitrateLabel,
            flagEmoji: station.flagEmoji,
            countryLocation: station.locationLabel,
            isPlaying: lastIsPlaying,
            isLoading: lastIsLoading,
            isBuffering: lastIsBuffering,
            faviconData: currentFaviconData
        )

        if let activity = currentActivity as? Activity<RadioActivityAttributes> {
            Task {
                await activity.update(
                    ActivityContent(state: state, staleDate: Date().addingTimeInterval(Self.staleInterval))
                )
            }
        } else if let existing = Activity<RadioActivityAttributes>.activities.first {
            currentActivity = existing
            Task {
                await existing.update(
                    ActivityContent(state: state, staleDate: Date().addingTimeInterval(Self.staleInterval))
                )
            }
        } else {
            do {
                let activity = try Activity.request(
                    attributes: RadioActivityAttributes(),
                    content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(Self.staleInterval)),
                    pushType: nil
                )
                currentActivity = activity
            } catch {
                // Live Activity not available or permission denied
            }
        }
    }
}

/// Type-erased protocol to store any Activity without exposing the generic parameter.
private protocol AnyLiveActivity {}

@available(iOS 16.2, *)
extension Activity: AnyLiveActivity {}
