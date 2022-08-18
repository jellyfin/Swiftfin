//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EpisodeCard: View {

    @EnvironmentObject
    private var itemRouter: ItemCoordinator.Router
    @ScaledMetric
    private var staticOverviewHeight: CGFloat = 50

    let episode: BaseItemDto

    var body: some View {
        PosterButton(item: episode, type: .landscape, singleImage: true)
            .scaleItem(1.2)
            .imageOverlay { _ in
                if episode.userData?.played ?? false {
                    ZStack(alignment: .bottomTrailing) {
                        Color.clear

                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30, alignment: .bottomTrailing)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
            .content { _ in
                VStack(alignment: .leading) {
                    Text(episode.episodeLocator ?? L10n.unknown)
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Text(episode.displayName)
                        .font(.body)
                        .padding(.bottom, 1)
                        .lineLimit(2)

                    ZStack(alignment: .topLeading) {
                        Color.clear
                            .frame(height: staticOverviewHeight)

                        if episode.unaired {
                            Text(episode.airDateLabel ?? L10n.noOverviewAvailable)
                        } else {
                            Text(episode.overview ?? L10n.noOverviewAvailable)
                        }
                    }
                    .font(.caption.weight(.light))
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                }
            }
            .onSelect { _ in
                itemRouter.route(to: \.item, episode)
            }
    }
}
