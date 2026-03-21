import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
@main
struct RadioLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RadioActivityAttributes.self) { context in
            lockScreenBanner(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.stationName)
                            .font(.headline)
                            .lineLimit(1)
                    } icon: {
                        faviconImage(data: context.state.faviconData, size: 24)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    playbackControls(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        if let flag = context.state.flagEmoji {
                            Text(flag)
                        }
                        if let countryLocation = context.state.countryLocation {
                            Text(countryLocation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let codec = context.state.codec {
                            Text(codec)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(context.state.bitrateLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                stateIcon(context: context)
            } minimal: {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(.cyan)
            }
        }
    }

    // MARK: - Lock Screen Banner

    @ViewBuilder
    private func lockScreenBanner(context: ActivityViewContext<RadioActivityAttributes>) -> some View {
        HStack {
            faviconImage(data: context.state.faviconData, size: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let flag = context.state.flagEmoji {
                        Text(flag)
                    }
                    Text(context.state.stationName)
                        .font(.headline)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    if let countryLocation = context.state.countryLocation {
                        Text(countryLocation)
                    }
                    if let codec = context.state.codec {
                        Text(codec)
                    }
                    Text(context.state.bitrateLabel)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            playbackControls(context: context)
        }
        .padding()
    }

    // MARK: - Playback Controls

    @ViewBuilder
    private func playbackControls(context: ActivityViewContext<RadioActivityAttributes>) -> some View {
        if #available(iOS 17.0, *) {
            HStack(spacing: 12) {
                Button(intent: TogglePlaybackIntent()) {
                    playPauseIcon(context: context)
                }
                Button(intent: StopPlaybackIntent()) {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.title2)
        } else {
            stateIcon(context: context)
                .font(.title2)
        }
    }

    @ViewBuilder
    private func playPauseIcon(context: ActivityViewContext<RadioActivityAttributes>) -> some View {
        if context.state.isLoading || context.state.isBuffering {
            Image(systemName: "ellipsis")
        } else if context.state.isPlaying {
            Image(systemName: "pause.fill")
                .foregroundStyle(.cyan)
        } else {
            Image(systemName: "play.fill")
                .foregroundStyle(.cyan)
        }
    }

    // MARK: - Favicon

    @ViewBuilder
    private func faviconImage(data: Data?, size: CGFloat) -> some View {
        if let data, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func stateIcon(context: ActivityViewContext<RadioActivityAttributes>) -> some View {
        if context.state.isLoading || context.state.isBuffering {
            Image(systemName: "ellipsis")
        } else if context.state.isPlaying {
            Image(systemName: "waveform")
                .foregroundStyle(.cyan)
        } else {
            Image(systemName: "pause.fill")
                .foregroundStyle(.secondary)
        }
    }
}
