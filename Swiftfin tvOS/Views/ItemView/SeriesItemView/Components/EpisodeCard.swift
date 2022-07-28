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

    let episode: BaseItemDto

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Button {
                
            } label: {
                ImageView(
                    episode.imageSource(.primary, maxWidth: 600)
                ) {
                    InitialFailureView(episode.failureInitials)
                }
                .frame(width: 550, height: 308)
            }
            .buttonStyle(CardButtonStyle())
            
            Button {
                itemRouter.route(to: \.item, episode)
            } label: {
                VStack(alignment: .leading) {

                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear
                            .frame(height: 0.01)
                            .frame(maxWidth: .infinity)
                        
                        Text(episode.episodeLocator ?? L10n.unknown)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(episode.displayName)
                        .font(.footnote)
                        .padding(.bottom, 1)

                    if episode.unaired {
                        Text(episode.airDateLabel ?? L10n.noOverviewAvailable)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.light)
                            .lineLimit(1)
                    } else {
                        Text(episode.overview ?? "--")
                            .font(.caption)
                            .fontWeight(.light)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(width: 510, height: 220)
                .padding(.horizontal)
            }
            .buttonStyle(CardButtonStyle())
        }
    }
}
