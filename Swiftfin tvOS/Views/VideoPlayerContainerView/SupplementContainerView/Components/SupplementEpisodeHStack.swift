//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension VideoPlayer.UIVideoPlayerContainerViewController.SupplementContainerView {

    struct SupplementEpisodeHStack: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        var viewModel: SeasonItemViewModel

        let action: (BaseItemDto) -> Void

        var body: some View {
            Group {
                switch viewModel.state {
                case .content:
                    if !viewModel.elements.isEmpty {
                        PosterHStack(
                            type: .landscape,
                            items: viewModel.elements
                        ) { episode in
                            action(episode)
                        } label: { episode in
                            PosterButton<BaseItemDto>.TitleSubtitleContentView(item: episode)
                                .lineLimit(2, reservesSpace: true)
                        }
                        .posterOverlay(for: BaseItemDto.self) { episode in
                            ZStack {
                                PosterButton<BaseItemDto>.DefaultOverlay(item: episode)

                                if episode.id == manager.item.id {
                                    ContainerRelativeShape()
                                        .stroke(
                                            accentColor,
                                            lineWidth: 16
                                        )
                                        .clipped()
                                }
                            }
                        }
                    }
                case .initial, .refreshing:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .error:
                    Label(L10n.error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}
