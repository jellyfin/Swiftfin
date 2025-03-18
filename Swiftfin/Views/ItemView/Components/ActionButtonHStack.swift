//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

// TODO: Favorited and played accessibility labels
//       based on value

extension ItemView {

    struct ActionButtonHStack: View {

        @Default(.accentColor)
        private var accentColor

        @Injected(\.downloadManager)
        private var downloadManager: DownloadManager

        @EnvironmentObject
        private var router: ItemCoordinator.Router
        @EnvironmentObject
        private var mainRouter: MainCoordinator.Router

        @ObservedObject
        private var viewModel: ItemViewModel

        private let equalSpacing: Bool

        init(viewModel: ItemViewModel, equalSpacing: Bool = true) {
            self.viewModel = viewModel
            self.equalSpacing = equalSpacing
        }

        private var hasTrailers: Bool {
            viewModel.item.remoteTrailers?.isNotEmpty == true ||
                viewModel.localTrailers.isNotEmpty
        }

        @ViewBuilder
        private var isPlayedButton: some View {
            let isPlayed = viewModel.item.userData?.isPlayed == true

            Button(
                L10n.played,
                systemImage: isPlayed ? "checkmark.circle.fill" : "checkmark.circle"
            ) {
                UIDevice.impact(.light)
                viewModel.send(.toggleIsPlayed)
            }
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                .primary,
                isPlayed ? AnyShapeStyle(accentColor) : AnyShapeStyle(.primary)
            )
        }

        @ViewBuilder
        private var isFavoriteButton: some View {
            let isFavorited = viewModel.item.userData?.isFavorite == true

            Button(
                L10n.favorited,
                systemImage: isFavorited ? "heart.fill" : "heart"
            ) {
                UIDevice.impact(.light)
                viewModel.send(.toggleIsFavorite)
            }
            .symbolRenderingMode(.palette)
            .foregroundStyle(isFavorited ? AnyShapeStyle(Color.red) : AnyShapeStyle(.primary))
        }

        @ViewBuilder
        private var trailerMenu: some View {
            Menu(L10n.trailers, systemImage: "movieclapper") {
                if viewModel.localTrailers.isNotEmpty {
                    Section(L10n.local) {
                        ForEach(viewModel.localTrailers, id: \.self) { trailer in
                            Button(trailer.name ?? L10n.trailer, systemImage: "play.fill") {
                                if let selectedMediaSource = trailer.mediaSources?.first {
                                    UIDevice.feedback(.success)
                                    mainRouter.route(
                                        to: \.videoPlayer,
                                        OnlineVideoPlayerManager(item: trailer, mediaSource: selectedMediaSource)
                                    )
                                } else {
                                    UIDevice.feedback(.error)
                                }
                            }
                        }
                    }
                }

                if let externaltrailers = viewModel.item.remoteTrailers {
                    Section(L10n.external) {
                        ForEach(externaltrailers, id: \.url) { trailer in
                            Button(trailer.name ?? L10n.trailer, systemImage: "arrow.up.forward") {
                                if let url = URL(string: trailer.url) {
                                    UIApplication.shared.open(url)
                                    UIDevice.feedback(.success)
                                } else {
                                    UIDevice.feedback(.error)
                                }
                            }
                        }
                    }
                }
            }
        }

        @ViewBuilder
        private func mediaSourcesMenu(mediaSources: [MediaSourceInfo]) -> some View {
            Menu(L10n.media, systemImage: "list.dash") {
                ForEach(mediaSources, id: \.hashValue) { mediaSource in
                    Button {
                        viewModel.send(.selectMediaSource(mediaSource))
                    } label: {
                        if let selectedMediaSource = viewModel.selectedMediaSource, selectedMediaSource == mediaSource {
                            Label(selectedMediaSource.displayTitle, systemImage: "checkmark")
                        } else {
                            Text(mediaSource.displayTitle)
                        }
                    }
                }
            }
        }

        var body: some View {
            HStack(alignment: .center, spacing: 15) {
                isPlayedButton
                    .if(equalSpacing) { view in
                        view.frame(maxWidth: .infinity)
                    }

                isFavoriteButton
                    .if(equalSpacing) { view in
                        view.frame(maxWidth: .infinity)
                    }

                if hasTrailers {
                    trailerMenu
                        .if(equalSpacing) { view in
                            view.frame(maxWidth: .infinity)
                        }
                }

                if let mediaSources = viewModel.playButtonItem?.mediaSources,
                   mediaSources.count > 1
                {
                    mediaSourcesMenu(mediaSources: mediaSources)
                        .if(equalSpacing) { view in
                            view.frame(maxWidth: .infinity)
                        }
                }

                if viewModel.item.type == .movie ||
                    viewModel.item.type == .episode,
                    Defaults[.Experimental.downloads]
                {
                    DownloadTaskButton(item: viewModel.item)
                        .onSelect { task in
                            router.route(to: \.downloadTask, task)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 25, height: 25)
                        .if(equalSpacing) { view in
                            view.frame(maxWidth: .infinity)
                        }
                }
            }
            .labelStyle(.iconOnly)
        }
    }
}

#Preview {
    VStack {

        let isFavorited = false

        Button(L10n.favorited, systemImage: isFavorited ? "heart.fill" : "heart") {}
            .symbolRenderingMode(.palette)
            .foregroundStyle(isFavorited ? AnyShapeStyle(Color.red) : AnyShapeStyle(.primary))

        let isPlayed = false

        Button(
            L10n.played,
            systemImage: isPlayed ? "checkmark.circle.fill" : "checkmark.circle"
        ) {
//            UIDevice.impact(.light)
//            viewModel.send(.toggleIsPlayed)
        }
        .symbolRenderingMode(.palette)
        .foregroundStyle(
            .primary,
            isPlayed ? AnyShapeStyle(Color.red) : AnyShapeStyle(.primary)
        )
    }
    .labelStyle(.iconOnly)
}
