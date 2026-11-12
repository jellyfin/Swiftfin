//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
struct PlaybackAdjustmentSupplement {

    let id: String
    let displayTitle: String
    let value: (MediaSession) -> Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let presets: [Double]
    let resetValue: Double
    let formatValue: (Double) -> String

    var preferredFocusID: String {
        "\(VideoPlayer.ViewState.Focus.supplementContent(id)).slider"
    }
}

extension PlaybackAdjustmentSupplement: VideoPlayerSupplement {

    @ContentBuilder
    var body: some View {
        AdjustmentView(supplement: self)
    }

    private struct AdjustmentView: PresentationView {

        @AdaptiveLayout
        private var viewLayout

        @Environment(VideoPlayer.ViewState.self)
        private var viewState

        @Environment(MediaSession.self)
        private var mediaSession

        let supplement: PlaybackAdjustmentSupplement

        @ContentBuilder
        private var content: some View {
            PlaybackAdjustmentSlider(
                value: supplement.value(mediaSession),
                title: supplement.displayTitle,
                range: supplement.range,
                step: supplement.step,
                presets: supplement.presets,
                resetValue: supplement.resetValue,
                formatValue: supplement.formatValue,
                focusID: supplement.preferredFocusID
            )
            .frame(maxWidth: viewLayout.isLarge ? 1200 : 700)
            .frame(maxWidth: .infinity)
            .edgePadding(.horizontal)
            .padding(.vertical, viewLayout.isLarge ? 24 : 12)
            .padding(.leading, viewState.supplementInsets.leading)
            .padding(.trailing, viewState.supplementInsets.trailing)
            .scrollIfLargerThanContainer()
            .padding(.bottom, viewState.supplementInsets.bottom)
        }

        @ContentBuilder
        var standardView: some View {
            content
        }

        @ContentBuilder
        var largeView: some View {
            content
                .focusSection()
        }
    }
}

extension PlaybackAdjustmentSupplement {

    static var audioOffset: Self {
        offset(
            id: "PlaybackAdjustment-audioOffset",
            title: L10n.audioOffset,
            keyPath: \.audioOffset
        )
    }

    static var subtitleOffset: Self {
        offset(
            id: "PlaybackAdjustment-subtitleOffset",
            title: L10n.subtitleOffset,
            keyPath: \.subtitleOffset
        )
    }

    static var secondarySubtitleOffset: Self {
        offset(
            id: "PlaybackAdjustment-secondarySubtitleOffset",
            title: L10n.secondarySubtitleOffset,
            keyPath: \.secondarySubtitleOffset
        )
    }

    static func playbackSpeed(range: ClosedRange<Double>) -> Self {
        Self(
            id: "PlaybackAdjustment-speed",
            displayTitle: L10n.playbackSpeed,
            value: { mediaSession in
                Binding(get: { mediaSession.effectiveRate }, set: { mediaSession.rate = $0 })
            },
            range: range,
            step: 0.05,
            presets: [0.5, 0.75, 1, 1.25, 1.5, 2],
            resetValue: 1,
            formatValue: { $0.formatted(.playbackRate(precision: 2)) }
        )
    }

    static func sleepTimer(_ sleepTimer: DeadlineTimer) -> Self {
        let start = Date(timeIntervalSinceReferenceDate: (Date.now.timeIntervalSinceReferenceDate / 60).rounded(.up) * 60)

        if sleepTimer.deadline == nil {
            sleepTimer.start(until: start.addingTimeInterval(30 * 60))
        }

        return Self(
            id: "PlaybackAdjustment-sleepTimer",
            displayTitle: L10n.sleepTimer,
            value: { _ in
                Binding(
                    get: { (sleepTimer.deadline?.timeIntervalSince(start) ?? 0) / 60 },
                    set: { sleepTimer.start(until: start.addingTimeInterval($0 * 60)) }
                )
            },
            range: 0 ... 1440,
            step: 1,
            presets: [15, 30, 60, 120, 240, 360],
            resetValue: 1,
            formatValue: { minutes in
                start.addingTimeInterval(minutes * 60).formatted(date: .omitted, time: .shortened)
            }
        )
    }

    private static func offset(
        id: String,
        title: String,
        keyPath: ReferenceWritableKeyPath<MediaPlayerItem, Duration>
    ) -> Self {
        Self(
            id: id,
            displayTitle: title,
            value: { mediaSession in
                Binding(
                    get: { Double((mediaSession.playbackItem?[keyPath: keyPath] ?? .zero).microseconds) / 1000 },
                    set: { mediaSession.playbackItem?[keyPath: keyPath] = .milliseconds(Int64($0.rounded())) }
                )
            },
            range: -5000 ... 5000,
            step: 50,
            presets: [-1000, -500, 0, 500, 1000],
            resetValue: 0,
            formatValue: { value in
                Duration.milliseconds(Int64(value.rounded()))
                    .formatted(.playbackOffset)
            }
        )
    }
}
