//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct EpisodeCard: View {

    @EnvironmentObject
    private var router: ItemCoordinator.Router
    @State
    private var cancellables = Set<AnyCancellable>()

    let episode: BaseItemDto

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Button {
                // TODO: Figure out ad-hoc video player view model creation
                episode.createVideoPlayerViewModel()
                    .sink(receiveCompletion: { _ in }) { viewModels in
                        guard !viewModels.isEmpty else { return }
                        self.router.route(to: \.videoPlayer, viewModels[0])
                    }
                    .store(in: &cancellables)
            } label: {
                ImageView(
                    episode.imageSource(.primary, maxWidth: 600)
                )
                .failure {
                    InitialFailureView(episode.title.initials)
                }
                .frame(width: 550, height: 308)
            }
            .buttonStyle(.card)

            Button {
                router.route(to: \.item, episode)
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
                            .lineLimit(1)
                    } else {
                        Text(episode.overview ?? L10n.noOverviewAvailable)
                            .font(.caption)
                            .lineLimit(3)
                    }

                    Spacer(minLength: 0)

                    L10n.seeMore.text
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(UIColor.systemCyan))
                }
                .frame(width: 510, height: 220)
                .padding()
            }
            .buttonStyle(.card)
        }
    }
}
