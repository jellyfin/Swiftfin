//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

extension OfflineItemView {

    struct ActionButtonHStack: View {

        @Injected(Container.downloadManager)
        private var downloadManager: DownloadManager

        @EnvironmentObject
        private var router: OfflineItemCoordinator.Router

        @ObservedObject
        private var viewModel: OfflineItemViewModel

        private let equalSpacing: Bool

        @State
        private var isConfirming = false

        init(viewModel: OfflineItemViewModel, equalSpacing: Bool = true) {
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
                                Color.jellyfinPurple
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

                Button {
                    UIDevice.impact(.light)
                    isConfirming = true
                } label: {
                    Image(systemName: "trash")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.red)
                }
                .confirmationDialog("Are you sure you want to delete this item?", isPresented: $isConfirming) {
                    Button {
                        if let task = viewModel.download {
                            downloadManager.remove(task: task)
                        }
                    } label: {
                        Text("Delete").foregroundStyle(Color.red)
                    }
                    Button("Don't delete", role: .cancel)
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
//                                viewModel.selectedMediaSource = mediaSource
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

                // TODO: Delete button
            }
        }
    }
}
