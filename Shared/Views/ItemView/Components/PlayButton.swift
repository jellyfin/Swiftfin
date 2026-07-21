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

    @State
    private var isShuffling = false

    private let playButtonFocus: FocusState<Bool>.Binding?

    init(
        provider: ItemContentGroupProvider,
        playButtonFocus: FocusState<Bool>.Binding? = nil
    ) {
        self.provider = provider
        self.playButtonFocus = playButtonFocus
    }

    private var mediaSource: String? {
        guard provider.item.mediaSources?.count ?? 0 > 1 else { return nil }
        return provider.selectedMediaSource?.displayTitle
    }

    /// When a shuffleable container (ie a boxset or collection) has no directly
    /// playable item, the primary button shuffles its children instead of playing.
    private var isShuffleOnly: Bool {
        provider.playButtonItem == nil && provider.item.canShuffle
    }

    private func play(fromBeginning: Bool = false) {
        guard let playButtonItem = provider.playButtonItem,
              let selectedMediaSource = provider.selectedMediaSource
        else {
            provider.logger.error("Play selected with no item or media source")
            return
        }

        // TODO: continue through container playback instead of a single item
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

    private func shuffle() {
        guard !isShuffling else { return }
        isShuffling = true

        Task {
            defer { isShuffling = false }

            do {
                guard let (firstItem, queue) = try await ShuffleMediaPlayerQueue.build(for: provider.item) else {
                    provider.logger.error("No items to shuffle")
                    return
                }

                let itemProvider = MediaPlayerItemProvider(item: firstItem) { item in
                    try await MediaPlayerItem.build(
                        for: item,
                        requestedBitrate: Defaults[.VideoPlayer.Playback.appMaximumBitrate]
                    ) {
                        $0.userData?.playbackPositionTicks = 0
                    }
                }

                router.route(
                    to: .videoPlayer(
                        provider: itemProvider,
                        queue: queue
                    )
                )
            } catch {
                provider.logger.error("Error shuffling item: \(error.localizedDescription)")
            }
        }
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
            if isShuffleOnly {
                shuffle()
            } else {
                play()
            }
        } label: {
            HStack {
                Image(systemName: isShuffleOnly ? "shuffle" : "play.fill")

                VStack(spacing: 2) {
                    Text(isShuffleOnly ? L10n.shuffle : (provider.playButtonItem?.playButtonLabel ?? L10n.play))

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
        .ifLet(playButtonFocus) { view, playButtonFocus in
            view.focused(playButtonFocus)
        }
        .contextMenu {
            if provider.playButtonItem?.userData?.playbackPositionTicks != 0 {
                Button(L10n.playFromBeginning, systemImage: "gobackward") {
                    play(fromBeginning: true)
                }
            }

            // When the primary button already shuffles, don't duplicate the action.
            if provider.item.canShuffle, !isShuffleOnly {
                Button(L10n.shuffle, systemImage: "shuffle") {
                    shuffle()
                }
                .disabled(isShuffling)
            }
        }
        .isSelected(true)
        .disabled(isShuffleOnly ? isShuffling : provider.selectedMediaSource == nil)
    }

    var body: some View {
        HStack(alignment: .center, spacing: UIDevice.isTV ? 30 : 10) {
            playButton

            versionMenu
        }
        .frame(height: UIDevice.isTV ? 75 : 44)
    }
}
