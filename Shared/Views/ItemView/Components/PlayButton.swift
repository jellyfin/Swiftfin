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
        guard let playButtonItem = provider.playButtonItem else {
            provider.logger.error("Play selected with no item")
            return
        }

        guard let selectedMediaSource = provider.selectedMediaSource else {
            guard playButtonItem.isAiring,
                  let userSession = provider.userSession
            else {
                provider.logger.error("Play selected with no media source")
                return
            }

            router.route(
                to: .videoPlayer(
                    provider: playButtonItem.getPlaybackItemProvider(userSession: userSession)
                )
            )
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
        if let mediaSources = provider.playButtonItem?.mediaSources,
           mediaSources.count > 1
        {
            Menu {
                Picker(
                    L10n.version,
                    sources: mediaSources,
                    selection: $provider.selectedMediaSource,
                    noneStyle: nil
                )
            } label: {
                #if os(tvOS)
                let shape: Rectangle = .rect
                #else
                let shape: RoundedRectangle = .rect(cornerRadius: 10, style: .circular)
                #endif

                Label {
                    Text(L10n.version)
                } icon: {
                    Image(systemName: "ellipsis")
                    #if os(tvOS)
                        .rotationEffect(.degrees(90))
                    #endif
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .backport
                .glassEffect(
                    .regular.selection(
                        tint: .clear,
                        foregroundColor: .primary
                    ),
                    in: shape
                )
            }
            .foregroundStyle(.primary, .secondary)
            .font(.title3)
            .fontWeight(.semibold)
            .menuStyle(.button)
            .labelStyle(.iconOnly)
            .buttonStyle(BasicHoverButtonStyle())
            #if !os(tvOS)
                .aspectRatio(1, contentMode: .fit)
            #else
                .frame(width: 60)
            #endif
        }
    }

    @ViewBuilder
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
        .backport
        .buttonBorderShape(.capsule)
        .buttonStyle(BasicHoverButtonStyle())
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
            .disabled(provider.selectedMediaSource == nil && provider.playButtonItem?.isAiring != true)
    }

    var body: some View {
        HStack(alignment: .center, spacing: UIDevice.isTV ? 30 : 10) {
            playButton

            versionMenu
        }
        .frame(height: UIDevice.isTV ? 75 : 44)
    }
}
