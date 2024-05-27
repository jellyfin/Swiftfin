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
import OrderedCollections
import SwiftUI

extension OfflineView {

    struct OfflineLibraryView: View {

        @Default(.Customization.latestInLibraryPosterType)
        private var latestInLibraryPosterType

        @EnvironmentObject
        private var mainRouter: MainCoordinator.Router

        @EnvironmentObject
        private var router: OfflineCoordinator.Router

        @ObservedObject
        var viewModel: DownloadLibraryViewModel

        @ObservedObject
        var offlineViewModel: OfflineViewModel

        var body: some View {
            if viewModel.elements.isNotEmpty {
                PosterHStack(
                    title: viewModel.parent?.displayTitle ?? .emptyDash,
                    type: latestInLibraryPosterType,
                    items: $viewModel.elements
                )
                .trailing {
                    SeeAllButton()
                        .onSelect {
                            // TODO:
//                            router.route(to: \.library, viewModel)
                        }
                }
                .contextMenu { item in
                    Button(role: .destructive) {
                        if let task = offlineViewModel.getDownloadForItem(item: item) {
                            offlineViewModel.send(.removeDownload(task))
                        }
                    } label: {
                        Label(L10n.remove, systemImage: "trash")
                    }
                }
                .onSelect { item in
                    // TODO: offline item view
                    router.route(to: \.item, item)
//                    if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
//                        mainRouter.route(
//                            to: \.videoPlayer,
//                            DownloadVideoPlayerManager(
//                                downloadTask: offlineViewModel.getDownloadForItem(item: item),
//                                offlineViewModel: offlineViewModel
//                            )
//                        )
//                    }
                }
            }
        }
    }
}
