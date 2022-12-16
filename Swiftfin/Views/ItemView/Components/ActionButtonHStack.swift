//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionButtonHStack: View {

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
                    viewModel.toggleWatchState()
                } label: {
                    if viewModel.isPlayed {
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
                    viewModel.toggleFavoriteState()
                } label: {
                    if viewModel.isFavorited {
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
                                viewModel.selectedMediaSource = mediaSource
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
            }
        }
    }
}
