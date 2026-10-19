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

    var body: some View {
        AdjustmentView(supplement: self)
    }

    private struct AdjustmentView: PlatformView {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @Environment(MediaSession.self)
        private var mediaSession

        let supplement: PlaybackAdjustmentSupplement

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
            .frame(maxWidth: UIDevice.isTV ? 1200 : 700)
            .frame(maxWidth: .infinity)
            .edgePadding(.horizontal)
            .padding(.vertical, UIDevice.isTV ? 24 : 12)
            .padding(.leading, safeAreaInsets.leading)
            .padding(.trailing, safeAreaInsets.trailing)
            .scrollIfLargerThanContainer()
            .padding(.bottom, safeAreaInsets.bottom)
        }

        var iOSView: some View {
            content
        }

        var tvOSView: some View {
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

    static var playbackSpeed: Self {
        Self(
            id: "PlaybackAdjustment-speed",
            displayTitle: L10n.playbackSpeed,
            value: { mediaSession in
                Binding(get: { mediaSession.rate }, set: { mediaSession.rate = $0 })
            },
            range: 0.1 ... 5,
            step: 0.05,
            presets: [0.5, 0.75, 1, 1.25, 1.5, 2],
            resetValue: 1,
            formatValue: { $0.formatted(.playbackRate(precision: 2)) }
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
