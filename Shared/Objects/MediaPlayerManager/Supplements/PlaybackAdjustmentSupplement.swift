//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PlaybackAdjustmentSupplement: MediaPlayerSupplement {

    let id: String
    let displayTitle: String
    let value: (MediaPlayerManager) -> Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let presets: [Double]
    let resetValue: Double
    let formatValue: (Double) -> String
    var description: String?

    var preferredFocusID: String {
        "\(VideoPlayer.ViewState.Focus.supplementContent(id)).slider"
    }

    var videoPlayerBody: some PlatformView {
        AdjustmentView(supplement: self)
    }
}

extension PlaybackAdjustmentSupplement {

    private struct AdjustmentView: PlatformView {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets
        @EnvironmentObject
        private var manager: MediaPlayerManager

        let supplement: PlaybackAdjustmentSupplement

        private var content: some View {
            ScrollView {
                VStack(spacing: 12) {
                    PlaybackAdjustmentSlider(
                        value: supplement.value(manager),
                        title: supplement.displayTitle,
                        range: supplement.range,
                        step: supplement.step,
                        presets: supplement.presets,
                        resetValue: supplement.resetValue,
                        formatValue: supplement.formatValue,
                        focusID: supplement.preferredFocusID
                    )

                    if let description = supplement.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: UIDevice.isTV ? 1000 : 700)
                .frame(maxWidth: .infinity)
                .edgePadding(.horizontal)
                .padding(.vertical, 12)
                .padding(.leading, safeAreaInsets.leading)
                .padding(.trailing, safeAreaInsets.trailing)
                .padding(.bottom, safeAreaInsets.bottom)
            }
            .scrollBounceBehavior(.basedOnSize)
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
        offset(id: "PlaybackAdjustment-audioOffset", title: L10n.audioOffset, keyPath: \.audioOffset)
    }

    static var subtitleOffset: Self {
        offset(id: "PlaybackAdjustment-subtitleOffset", title: L10n.subtitleOffset, keyPath: \.subtitleOffset)
    }

    static var playbackSpeed: Self {
        Self(
            id: "PlaybackAdjustment-speed",
            displayTitle: L10n.playbackSpeed,
            value: { manager in
                Binding(get: { manager.rate }, set: { manager.rate = $0 })
            },
            range: 0.1 ... 10,
            step: 0.05,
            presets: [0.5, 0.75, 1, 1.25, 1.5, 2],
            resetValue: 1,
            formatValue: { $0.formatted(.playbackRate(precision: 2)) }
        )
    }

    private static func offset(
        id: String,
        title: String,
        keyPath: ReferenceWritableKeyPath<MediaPlayerManager, Duration>
    ) -> Self {
        Self(
            id: id,
            displayTitle: title,
            value: { manager in
                Binding(
                    get: { Double(manager[keyPath: keyPath].microseconds) / 1000 },
                    set: { manager[keyPath: keyPath] = .milliseconds(Int64($0.rounded())) }
                )
            },
            range: -5000 ... 5000,
            step: 50,
            presets: [-1000, -500, 0, 500, 1000],
            resetValue: 0,
            formatValue: { value in
                Duration.milliseconds(Int64(value.rounded()))
                    .formatted(.playbackOffset)
            },
            description: L10n.playbackOffsetDescription
        )
    }
}
