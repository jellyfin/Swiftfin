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

extension ItemView {

    struct ActionButtonHStack: View {

        @Default(.accentColor)
        private var accentColor

        @Injected(\.downloadManager)
        private var downloadManager: DownloadManager

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        private var viewModel: ItemViewModel

        private let equalSpacing: Bool

        init(viewModel: ItemViewModel, equalSpacing: Bool = true) {
            self.viewModel = viewModel
            self.equalSpacing = equalSpacing
        }

        var body: some View {
            HStack(alignment: .center, spacing: 15) {
                Button {
                    UIDevice.impact(.light)
                    viewModel.send(.toggleIsPlayed)
                } label: {
                    if viewModel.item.userData?.isPlayed ?? false {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                .primary,
                                accentColor
                            )
                    } else {
                        Image(systemName: "checkmark.circle")
                    }
                }
                .buttonStyle(.plain)
                .if(equalSpacing) { view in
                    view.frame(maxWidth: .infinity)
                }

                Button {
                    UIDevice.impact(.light)
                    viewModel.send(.toggleIsFavorite)
                } label: {
                    if viewModel.item.userData?.isFavorite ?? false {
                        Image(systemName: "heart.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.red)
                    } else {
                        Image(systemName: "heart")
                    }
                }
                .buttonStyle(.plain)
                .if(equalSpacing) { view in
                    view.frame(maxWidth: .infinity)
                }

                if let playButtonItem = viewModel.playButtonItem,
                   let mediaSources = playButtonItem.mediaSources,
                   mediaSources.count > 1
                {
                    Menu {
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
                    } label: {
                        Image(systemName: "list.dash")
                    }
                    .buttonStyle(.plain)
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
        }
    }
}
