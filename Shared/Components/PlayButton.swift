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
    var viewModel: _ItemViewModel

    @Router
    private var router

    private let logger = Logger.swiftfin()

    private var mediaSource: String? {
        guard viewModel.item.mediaSources?.count ?? 0 > 1 else { return nil }
        return viewModel.selectedMediaSource?.displayTitle
    }

    private func play(fromBeginning: Bool = false) {
        guard let playButtonItem = viewModel.playButtonItem,
              let selectedMediaSource = viewModel.selectedMediaSource
        else {
            logger.error("Play selected with no item or media source")
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

    @ViewBuilder
    private var versionMenu: some View {
        if let mediaSources = viewModel.playButtonItem?.mediaSources,
           mediaSources.count > 1
        {
            Menu(L10n.version, systemImage: "list.dash") {
                Picker(
                    L10n.version,
                    sources: mediaSources,
                    selection: $viewModel.selectedMediaSource,
                    noneStyle: nil
                )
            }
            .menuStyle(.button)
            .labelStyle(
                .tintedMaterial(
                    tint: .white,
                    foregroundColor: .black
                )
            )
            .labelStyle(.iconOnly)
            .aspectRatio(1, contentMode: .fit)
        }
    }

    private var playButton: some View {
        Button {
            play()
        } label: {
            HStack {
                Image(systemName: "play.fill")

                VStack(spacing: 2) {
                    Text(viewModel.playButtonItem?.playButtonLabel ?? L10n.play)

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
        .contextMenu {
            if viewModel.playButtonItem?.userData?.playbackPositionTicks != 0 {
                Button(L10n.playFromBeginning, systemImage: "gobackward") {
                    play(fromBeginning: true)
                }
            }
        }
        .isSelected(true)
        .disabled(viewModel.selectedMediaSource == nil)
    }

    var body: some View {
        HStack {
            playButton

            versionMenu
        }
        .frame(height: UIDevice.isTV ? 100 : 44)
    }
}

struct InlineLabelStyle<Content: View>: LabelStyle {

    private let content: (Configuration) -> Content

    init(@ViewBuilder content: @escaping (Configuration) -> Content) {
        self.content = content
    }

    func makeBody(configuration: Configuration) -> some View {
        content(configuration)
    }
}
