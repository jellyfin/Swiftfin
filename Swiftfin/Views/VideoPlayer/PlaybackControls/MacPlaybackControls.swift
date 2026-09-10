//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(macOS)
import Defaults
import JellyfinAPI
import SwiftUI

extension VideoPlayer {

    /// A Mac native playback overlay: a title scrim along the top edge
    /// and a single floating control bar along the bottom edge.
    ///
    /// This replaces the touch sized iOS overlay, which presents oversized
    /// center buttons and full bleed bars that do not belong in a window.
    struct MacPlaybackControls: View {

        private enum Layout {
            static let barInset: CGFloat = 18
            static let barCornerRadius: CGFloat = 16
            static let clusterSpacing: CGFloat = 14
            static let controlSpacing: CGFloat = 8
        }

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval
        @Default(.VideoPlayer.Overlay.trailingTimestampType)
        private var trailingTimestampType

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

        @ObservedObject
        private var windowState = MacWindowState.shared

        @Router
        private var router

        @State
        private var availableWidth: CGFloat = 0

        /// The floating Picture in Picture window is far too narrow for the
        /// full control cluster, so the bar sheds everything reachable by
        /// other means below this width.
        private var isCompactBar: Bool {
            availableWidth > 0 && availableWidth < 620
        }

        private var barInset: CGFloat {
            isCompactBar ? 8 : Layout.barInset
        }

        private var barCornerRadius: CGFloat {
            isCompactBar ? 10 : Layout.barCornerRadius
        }

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
        }

        private var runtime: Duration? {
            guard let runtime = manager.item.runtime, runtime > .zero else { return nil }
            return runtime
        }

        private var shouldShowJumpButtons: Bool {
            !manager.item.isLiveStream
        }

        // MARK: top bar

        @ViewBuilder
        private var titleContent: some View {
            VStack(alignment: .leading, spacing: 1) {
                if manager.item.type == .episode, let parentTitle = manager.item.parentTitle {
                    Text(parentTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: 6) {
                        if let seasonEpisodeLabel = manager.item.seasonEpisodeLabel {
                            Text(seasonEpisodeLabel)
                        }

                        Text(manager.item.displayTitle)
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.tail)
                } else {
                    Text(manager.item.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .foregroundStyle(.white)
        }

        @ViewBuilder
        private var topBar: some View {
            HStack(spacing: Layout.clusterSpacing) {
                MacControlButton(
                    systemImage: "xmark",
                    help: L10n.close,
                    isOverVideo: true
                ) {
                    manager.stop()
                    router.dismiss()
                }

                titleContent

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Layout.barInset)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                EasedGradient(
                    colors: [.black.opacity(0.65), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
            // the container treats clicks on the video as play/pause, so the
            // bar must swallow clicks that land on its own chrome
            .contentShape(Rectangle())
            .onTapGesture {}
        }

        // MARK: bottom bar

        @ViewBuilder
        private var playPauseButton: some View {
            MacControlButton(
                systemImage: manager.playbackRequestStatus == .playing ? "pause.fill" : "play.fill",
                help: manager.playbackRequestStatus == .playing ? L10n.pause : L10n.play,
                isOverVideo: false
            ) {
                manager.togglePlayPause()
            }
        }

        @ViewBuilder
        private var jumpBackwardButton: some View {
            MacControlButton(
                systemImage: jumpBackwardInterval.secondarySystemImage,
                help: L10n.jumpBackward,
                isOverVideo: false
            ) {
                manager.proxy?.jumpBackward(jumpBackwardInterval.rawValue)
            }
        }

        @ViewBuilder
        private var jumpForwardButton: some View {
            MacControlButton(
                systemImage: jumpForwardInterval.systemImage,
                help: L10n.jumpForward,
                isOverVideo: false
            ) {
                manager.proxy?.jumpForward(jumpForwardInterval.rawValue)
            }
        }

        /// Seeks directly instead of relying on `VideoPlayer`'s `isScrubbing`
        /// observer, which drops scrubs shorter than 100ms.
        private func commitScrub(to seconds: Double) {
            let target = Duration.seconds(seconds)
            manager.seconds = target
            manager.proxy?.setSeconds(target)
        }

        @ViewBuilder
        private var scrubber: some View {
            if let runtime {
                MacScrubber(
                    seconds: $scrubbedSecondsBox.value.map(
                        getter: { $0.seconds },
                        setter: { .seconds($0) }
                    ),
                    total: runtime.seconds,
                    isScrubbing: containerState.isScrubbing,
                    onEditingChanged: { containerState.isScrubbing = $0 },
                    onCommit: commitScrub
                )
            } else {
                // live streams and unknown runtimes have nothing to scrub against
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.2))
                    .frame(height: 7)
                    .frame(height: 24)
            }
        }

        @ViewBuilder
        private var trailingTimestamp: some View {
            Button {
                switch trailingTimestampType {
                case .timeLeft:
                    trailingTimestampType = .totalTime
                case .totalTime:
                    trailingTimestampType = .timeLeft
                }
            } label: {
                Group {
                    if let runtime {
                        switch trailingTimestampType {
                        case .timeLeft:
                            Text(.zero - (runtime - scrubbedSeconds), format: .runtime)
                        case .totalTime:
                            Text(runtime, format: .runtime)
                        }
                    } else {
                        Text(String.emptyRuntime)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }

        @ViewBuilder
        private var aspectFillButton: some View {
            // `VideoPlayerActionButton.aspectFill` uses the same diagonal arrows
            // as the full screen control, which reads as two identical buttons
            // sitting next to each other. Use the rectangle pair instead so the
            // two adjacent controls are distinguishable at a glance.
            MacControlButton(
                systemImage: containerState.isAspectFilled
                    ? "rectangle.arrowtriangle.2.inward"
                    : "rectangle.arrowtriangle.2.outward",
                help: L10n.aspectFill,
                isOverVideo: false
            ) {
                containerState.isAspectFilled.toggle()
            }
        }

        @ViewBuilder
        private var fullScreenButton: some View {
            MacControlButton(
                systemImage: windowState.isFullScreen
                    ? "arrow.down.right.and.arrow.up.left"
                    : "arrow.up.left.and.arrow.down.right",
                help: windowState.isFullScreen ? L10n.exitFullScreen : L10n.enterFullScreen,
                isOverVideo: false
            ) {
                windowState.toggleFullScreen()
            }
        }

        @ViewBuilder
        private var pictureInPictureButton: some View {
            MacControlButton(
                systemImage: windowState.isFloating
                    ? "pip.exit"
                    : "pip.enter",
                help: windowState.isFloating ? L10n.exitPictureInPicture : L10n.enterPictureInPicture,
                isOverVideo: false
            ) {
                windowState.toggleFloating()
            }
        }

        @ViewBuilder
        private var audioButton: some View {
            VideoPlayer.PlaybackControls.Toolbar.ActionButtons.Audio()
                .modifier(MacMenuChrome())
                .help(L10n.audio)
        }

        @ViewBuilder
        private var subtitleButton: some View {
            VideoPlayer.PlaybackControls.Toolbar.ActionButtons.Subtitles()
                .modifier(MacMenuChrome())
                .help(L10n.subtitles)
        }

        @ViewBuilder
        private var bottomBar: some View {
            HStack(spacing: isCompactBar ? Layout.controlSpacing : Layout.clusterSpacing) {
                HStack(spacing: Layout.controlSpacing) {
                    playPauseButton

                    if shouldShowJumpButtons, !isCompactBar {
                        jumpBackwardButton
                        jumpForwardButton
                    }
                }

                Text(scrubbedSeconds, format: .runtime)
                    .foregroundStyle(.secondary)

                scrubber
                    .frame(maxWidth: .infinity)

                if !isCompactBar {
                    trailingTimestamp
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: Layout.controlSpacing) {
                    // the floating window is too narrow for the full cluster,
                    // so keep only what cannot be reached another way
                    if !isCompactBar {
                        audioButton
                        subtitleButton
                        aspectFillButton
                    }

                    pictureInPictureButton

                    if !isCompactBar {
                        fullScreenButton
                    }
                }
            }
            .font(.footnote.monospacedDigit())
            .padding(.horizontal, isCompactBar ? 10 : 14)
            .padding(.vertical, isCompactBar ? 7 : 10)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: barCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: barCornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.08))
            }
            .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
            // the container treats clicks on the video as play/pause, so the
            // bar must swallow clicks that land on its own chrome
            .contentShape(RoundedRectangle(cornerRadius: barCornerRadius, style: .continuous))
            .onTapGesture {}
            .padding(barInset)
        }

        // MARK: body

        var body: some View {
            GeometryReader { proxy in
                ZStack {
                    VStack(spacing: 0) {
                        topBar
                            .opacity(isPresentingOverlay ? 1 : 0)
                            .allowsHitTesting(isPresentingOverlay)
                            .animation(.easeInOut(duration: 0.2), value: isPresentingOverlay)

                        Spacer(minLength: 0)
                            .allowsHitTesting(false)

                        bottomBar
                            .opacity(isPresentingOverlay ? 1 : 0)
                            .allowsHitTesting(isPresentingOverlay)
                            .animation(.easeInOut(duration: 0.2), value: isPresentingOverlay)
                    }

                    if let isBuffering = manager.proxy?.isBuffering {
                        MacBufferingIndicator(isBuffering: isBuffering)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .onChange(of: proxy.size.width, initial: true) {
                    availableWidth = proxy.size.width
                }
            }
            .disabled(manager.error != nil)
        }
    }
}

// MARK: - MacControlChrome

/// Sizes an icon control for a desktop bar and brightens it while hovered.
private struct MacControlChrome: ViewModifier {

    let isOverVideo: Bool

    @State
    private var isHovering: Bool = false

    private var foregroundColor: Color {
        if isOverVideo {
            isHovering ? .white : .white.opacity(0.75)
        } else {
            isHovering ? .primary : .secondary
        }
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
    }
}

// MARK: - MacMenuChrome

/// Renders a shared action button menu as a bare icon that fits a desktop bar.
private struct MacMenuChrome: ViewModifier {

    func body(content: Content) -> some View {
        content
            .labelStyle(.iconOnly)
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .modifier(MacControlChrome(isOverVideo: false))
    }
}

// MARK: - MacControlButton

private struct MacControlButton: View {

    let systemImage: String
    let help: String
    let isOverVideo: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .contentTransition(.symbolEffect(.replace))
                .modifier(MacControlChrome(isOverVideo: isOverVideo))
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

// MARK: - MacScrubber

/// A desktop scrubber that grows while hovered or scrubbed.
///
/// Commits the seek itself rather than leaning on `VideoPlayer`'s
/// `isScrubbing` observer: that path discards any scrub shorter than 100ms,
/// which is every ordinary click on the track.
private struct MacScrubber: View {

    @Binding
    var seconds: Double

    let total: Double
    let isScrubbing: Bool
    let onEditingChanged: (Bool) -> Void
    let onCommit: (Double) -> Void

    @State
    private var isEditing: Bool = false
    @State
    private var isHovering: Bool = false

    private var isActive: Bool {
        isEditing || isScrubbing || isHovering
    }

    private var trackHeight: CGFloat {
        isActive ? 10 : 7
    }

    private func value(atX x: CGFloat, width: CGFloat) -> Double {
        guard width > 0, x.isFinite else { return 0 }
        return clamp(Double(x / width), min: 0, max: 1) * total
    }

    private func beginEditing() {
        guard !isEditing else { return }
        isEditing = true
        onEditingChanged(true)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let progress = total > 0 ? clamp(seconds / total, min: 0, max: 1) : 0
            let knobX = width * CGFloat(progress)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.2))

                Capsule(style: .continuous)
                    .fill(Color.primary)
                    .frame(width: knobX)
            }
            .frame(height: trackHeight)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 13, height: 13)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .offset(x: knobX - 6.5)
                    .opacity(isActive ? 1 : 0)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        beginEditing()
                        seconds = value(atX: gesture.location.x, width: width)
                    }
                    .onEnded { gesture in
                        // A click delivers `onEnded` with no preceding
                        // `onChanged`, so opening the scrub here too keeps
                        // click-to-seek working.
                        beginEditing()

                        let target = value(atX: gesture.location.x, width: width)
                        seconds = target

                        // Seek before clearing the flag: the proxy overwrites
                        // `scrubbedSeconds` from its own clock as soon as
                        // scrubbing ends, which would snap the bar backwards.
                        onCommit(target)

                        isEditing = false
                        onEditingChanged(false)
                    }
            )
        }
        .frame(height: 24)
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}

// MARK: - MacBufferingIndicator

/// Observes the proxy's buffering box directly so the spinner updates
/// without depending on unrelated manager changes.
private struct MacBufferingIndicator: View {

    @ObservedObject
    var isBuffering: PublishedBox<Bool>

    var body: some View {
        if isBuffering.value {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
                .allowsHitTesting(false)
        }
    }
}
#endif
