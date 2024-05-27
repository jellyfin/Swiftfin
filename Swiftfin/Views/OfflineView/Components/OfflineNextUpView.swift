//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import JellyfinAPI
import SwiftUI

extension OfflineView {

    struct OfflineNextUpView: View {

        @Default(.Customization.nextUpPosterType)
        private var nextUpPosterType

        @EnvironmentObject
        private var router: HomeCoordinator.Router

        @ObservedObject
        var offlineViewModel: OfflineViewModel

        var body: some View {
            if offlineViewModel.nextUpViewModel.elements.isNotEmpty {
                PosterHStack(
                    title: L10n.nextUp,
                    type: nextUpPosterType,
                    items: $offlineViewModel.nextUpViewModel.elements
                )
                .content { item in
                    if item.type == .episode {
                        PosterButton.EpisodeContentSubtitleContent(item: item)
                    } else {
                        PosterButton.TitleSubtitleContentView(item: item)
                    }
                }
                .contextMenu { item in
                    Button {
                        if let task = offlineViewModel.getDownloadForItem(item: item) {
                            offlineViewModel.send(.setIsPlayed(true, task))
                        }
                    } label: {
                        Label(L10n.played, systemImage: "checkmark.circle")
                    }
                }
                .onSelect { item in
                    router.route(to: \.item, item)
                }
                .trailing {
                    SeeAllButton()
                        .onSelect {
                            router.route(to: \.library, offlineViewModel.nextUpViewModel)
                        }
                }
            }
        }
    }
}
