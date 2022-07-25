//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EpisodeRowCard: View {

    @EnvironmentObject
    var itemRouter: ItemCoordinator.Router
    let viewModel: EpisodesRowManager
    let episode: BaseItemDto

    var body: some View {
        Button {
            itemRouter.route(to: \.item, episode)
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
//                    ImageView(
//                        episode.getBackdropImage(maxWidth: 200),
//                        blurHash: episode.getBackdropImageBlurHash()
//                    )
                    ImageView(viewModel.item.imageViewSource(.backdrop, maxWidth: 200))
                    .frame(width: 200, height: 112)
                    .cornerRadius(10)
                    .padding(.top)
                    .accessibilityIgnoresInvertColors()

                    VStack(alignment: .leading) {
                        Text(episode.seasonEpisodeLocator ?? L10n.unknown)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(episode.name ?? L10n.noTitle)
                            .font(.body)
                            .padding(.bottom, 1)
                            .lineLimit(2)

                        if episode.unaired {
                            Text(episode.airDateLabel ?? L10n.noOverviewAvailable)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.light)
                                .lineLimit(3)
                        } else {
                            Text(episode.overview ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.light)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer()
                }
                .frame(width: 200)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
