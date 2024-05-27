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

    struct OfflineContinueWatchingView: View {
        @State
        private var isPresentingVideoPlayerTypeError: Bool = false

        @EnvironmentObject
        private var mainRouter: MainCoordinator.Router

        @EnvironmentObject
        private var router: OfflineCoordinator.Router

        @ObservedObject
        var viewModel: OfflineViewModel

        // TODO: see how this looks across multiple screen sizes
        //       alongside PosterHStack + landscape
        // TODO: need better handling for iPadOS + portrait orientation
        private var columnCount: CGFloat {
            if UIDevice.isPhone {
                1.5
            } else {
                3.5
            }
        }

        var body: some View {
            CollectionHStack(
                $viewModel.resumeItems,
                columns: columnCount
            ) { download in
                PosterButton(item: download, type: .landscape)
                    .content {
                        if download.item.type == .episode {
                            PosterButton.EpisodeContentSubtitleContent(item: download.item)
                        } else {
                            PosterButton.TitleSubtitleContentView(item: download.item)
                        }
                    }
                    .contextMenu {
                        Button {
                            viewModel.send(.setIsPlayed(true, download))
                        } label: {
                            Label(L10n.played, systemImage: "checkmark.circle")
                        }

//                        Button(role: .destructive) {
//                            viewModel.send(.setIsPlayed(false, item))
//                        } label: {
//                            Label(L10n.unplayed, systemImage: "minus.circle")
//                        }
                        Button(role: .destructive) {
                            viewModel.send(.removeDownload(download))
                        } label: {
                            Label(L10n.remove, systemImage: "trash")
                        }
                    }
                    .imageOverlay {
                        LandscapePosterProgressBar(
                            title: download.item.progressLabel ?? L10n.continue,
                            progress: (download.item.userData?.playedPercentage ?? 0) / 100
                        )
                    }
                    .onSelect {
                        // TODO: offline item view
                        if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                            mainRouter.route(
                                to: \.videoPlayer,
                                DownloadVideoPlayerManager(downloadTask: download, offlineViewModel: viewModel)
                            )
                        } else {
                            isPresentingVideoPlayerTypeError = true
                        }
                    }
            }
            .scrollBehavior(.continuousLeadingEdge)
            .alert(
                L10n.error,
                isPresented: $isPresentingVideoPlayerTypeError
            ) {
                Button {
                    isPresentingVideoPlayerTypeError = false
                } label: {
                    Text(L10n.dismiss)
                }
            } message: {
                Text("Downloaded items are only playable through the Swiftfin video player.")
            }
        }
    }
}
