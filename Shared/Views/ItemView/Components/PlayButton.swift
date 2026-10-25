//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Logging
import SwiftUI

struct PlayButton: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var provider: ItemContentGroupProvider

    @PlayMedia
    private var playMedia

    private var mediaSource: String? {
        guard provider.playbackIntent?.item.mediaSources?.count ?? 0 > 1 else { return nil }

        return provider.playbackIntent?.mediaSource?.displayTitle
    }

    private func play(fromBeginning: Bool = false) {
        guard var playbackIntent = provider.playbackIntent else {
            provider.logger.error("Play selected with no playback intent")
            return
        }

        if fromBeginning {
            playbackIntent.configuration.startSeconds = .zero
        }

        playMedia(intent: playbackIntent)
    }

    var body: some View {
        Button {
            play()
        } label: {
            HStack {
                Image(systemName: "play.fill")

                VStack(spacing: 2) {
                    Text(provider.playbackIntent?.item.playButtonLabel ?? L10n.play)

                    if let mediaSource {
                        Marquee(mediaSource, speed: 40, delay: 3, fade: 5)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .font(.callout)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .backport
            .glassEffect(
                .regular.selection(
                    tint: accentColor,
                    foregroundColor: accentColor.overlayColor
                ),
                in: .capsule
            )
        }
        .buttonBorderShape(.capsule)
        .buttonStyle(BasicHoverButtonStyle())
        .accessibilityLabel(L10n.play)
        .accessibilityValue(provider.playbackIntent?.item.playButtonLabel ?? L10n.play)
        .contextMenu {
            if (provider.playbackIntent?.item.userData?.playbackPositionTicks ?? 0) > 0 {
                Button(L10n.playFromBeginning, systemImage: "gobackward") {
                    play(fromBeginning: true)
                }
            }
        }
        .disabled(provider.playbackIntent == nil)
    }
}
