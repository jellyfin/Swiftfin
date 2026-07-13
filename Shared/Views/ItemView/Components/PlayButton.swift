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
    private var provider: ItemContentGroupProvider

    @Router
    private var router

    #if os(tvOS)
    private let playButtonFocus: FocusState<Bool>.Binding

    init(
        provider: ItemContentGroupProvider,
        playButtonFocus: FocusState<Bool>.Binding
    ) {
        self.provider = provider
        self.playButtonFocus = playButtonFocus
    }
    #else
    init(provider: ItemContentGroupProvider) {
        self.provider = provider
    }
    #endif

    private var mediaSource: String? {
        guard provider.item.mediaSources?.count ?? 0 > 1 else { return nil }
        return provider.selectedMediaSource?.displayTitle
    }

    private func play(fromBeginning: Bool = false) {
        guard let playButtonItem = provider.playButtonItem,
              let selectedMediaSource = provider.selectedMediaSource
        else {
            provider.logger.error("Play selected with no item or media source")
            return
        }

        let queue: (any MediaPlayerQueue)? = {
            if playButtonItem.type == .episode {
                return EpisodeMediaPlayerQueue(episode: playButtonItem)
            }
            return nil
        }()

        let provider = MediaPlayerItemProvider(item: playButtonItem) { item in
            try await MediaPlayerItem.build(
                for: item,
                mediaSource: selectedMediaSource
            ) {
                if fromBeginning {
                    $0.userData?.playbackPositionTicks = 0
                }
            }
        }

        router.route(
            to: .videoPlayer(
                provider: provider,
                queue: queue
            )
        )
    }

    private var playButton: some View {
        Button {
            play()
        } label: {
            HStack {
                Image(systemName: "play.fill")

                VStack(spacing: 2) {
                    Text(provider.playButtonItem?.playButtonLabel ?? L10n.play)

                    if let mediaSource {
                        Marquee(mediaSource, speed: 40, delay: 3, fade: 5)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .font(.callout)
            .fontWeight(.semibold)
        }
        .foregroundStyle(accentColor.overlayColor, accentColor)
        .buttonStyle(.primary)
        #if os(tvOS)
            .focused(playButtonFocus)
        #endif
            .contextMenu {
                if provider.playButtonItem?.userData?.playbackPositionTicks != 0 {
                    Button(L10n.playFromBeginning, systemImage: "gobackward") {
                        play(fromBeginning: true)
                    }
                }
            }
            .isSelected(true)
            .disabled(provider.selectedMediaSource == nil)
    }

    var body: some View {
        HStack {
            playButton
        }
        .frame(height: UIDevice.isTV ? 100 : 44)
    }
}
