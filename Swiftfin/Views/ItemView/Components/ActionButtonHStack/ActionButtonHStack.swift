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

// TODO: replace `equalSpacing` handling with a `Layout`

extension ItemView {

    struct ActionButtonHStack: View {

        @Default(.accentColor)
        private var accentColor

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        @ObservedObject
        private var viewModel: ItemViewModel

        @Injected(\.downloadManager)
        private var downloadManager

        @Router
        private var router

        private let equalSpacing: Bool

        private let enableDownload: Bool

        // MARK: - Has Trailers

        private var hasTrailers: Bool {
            if enabledTrailers.contains(.local), viewModel.localTrailers.isNotEmpty {
                return true
            }

            if enabledTrailers.contains(.external), viewModel.item.remoteTrailers?.isNotEmpty == true {
                return true
            }

            return false
        }

        // MARK: - Initializer

        init(viewModel: ItemViewModel, equalSpacing: Bool = true) {
            self.viewModel = viewModel
            self.equalSpacing = equalSpacing
            self.enableDownload = viewModel.isDownloadable
        }

        // MARK: - Body

        var body: some View {
            HStack(alignment: .center, spacing: 15) {

                // MARK: Toggle Played

                /// Marking Persons and Artists as played doesn't do anything.
                if viewModel.item.type != .person && viewModel.item.type != .musicArtist {

                    let isCheckmarkSelected = viewModel.item.userData?.isPlayed == true

                    ActionButton(
                        L10n.played,
                        icon: "checkmark.circle",
                        selectedIcon: "checkmark.circle.fill"
                    ) {
                        UIDevice.impact(.light)
                        viewModel.send(.toggleIsPlayed)
                    }
                    .environment(\.isSelected, isCheckmarkSelected)
                    .if(isCheckmarkSelected) { item in
                        item
                            .foregroundStyle(
                                .primary,
                                accentColor
                            )
                    }
                    .if(equalSpacing) { view in
                        view.frame(maxWidth: .infinity)
                    }
                }

                // MARK: Toggle Favorite

                let isHeartSelected = viewModel.item.userData?.isFavorite == true

                ActionButton(
                    L10n.favorited,
                    icon: "heart",
                    selectedIcon: "heart.fill"
                ) {
                    UIDevice.impact(.light)
                    viewModel.send(.toggleIsFavorite)
                }
                .environment(\.isSelected, isHeartSelected)
                .if(isHeartSelected) { item in
                    item
                        .foregroundStyle(Color.red)
                }
                .if(equalSpacing) { view in
                    view.frame(maxWidth: .infinity)
                }

                // MARK: Select a Version

                if let mediaSources = viewModel.playButtonItem?.mediaSources,
                   mediaSources.count > 1
                {
                    VersionMenu(viewModel: viewModel, mediaSources: mediaSources)
                        .if(equalSpacing) { view in
                            view.frame(maxWidth: .infinity)
                        }
                }

                // MARK: Watch a Trailer

                if hasTrailers {
                    TrailerMenu(
                        localTrailers: viewModel.localTrailers,
                        externalTrailers: viewModel.item.remoteTrailers ?? []
                    )
                    .if(equalSpacing) { view in
                        view.frame(maxWidth: .infinity)
                    }
                }

                if enableDownload {
                    DownloadTaskButton(item: viewModel.item)
                        .onSelect { _ in
                            // Download functionality is now handled inline in the button
                            // No need to open modal or route to download task view
                        }
                        .if(equalSpacing) { view in
                            view.frame(maxWidth: .infinity)
                        }
                }
            }
        }
    }
}
