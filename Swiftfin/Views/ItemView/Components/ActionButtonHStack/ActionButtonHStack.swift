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
        @EnvironmentObject
        private var mainRouter: MainCoordinator.Router

        @ObservedObject
        private var viewModel: ItemViewModel

        private let equalSpacing: Bool

        // MARK: - Has Trailers

        private var hasTrailers: Bool {
            viewModel.item.remoteTrailers?.isNotEmpty == true ||
                viewModel.localTrailers.isNotEmpty
        }

        // MARK: - Initializer

        init(viewModel: ItemViewModel, equalSpacing: Bool = true) {
            self.viewModel = viewModel
            self.equalSpacing = equalSpacing
        }

        // MARK: - Body

        var body: some View {
            HStack(alignment: .center, spacing: 15) {

                // MARK: Toggle Played

                ActionButton(
                    L10n.played,
                    icon: "checkmark.circle",
                    selectedIcon: "checkmark.circle.fill",
                    color: Color.jellyfinPurple,
                    multicolor: true
                ) {
                    UIDevice.impact(.light)
                    viewModel.send(.toggleIsPlayed)
                }
                .environment(\.isSelected, viewModel.item.userData?.isPlayed == true)
                .if(equalSpacing) { view in
                    view.frame(maxWidth: .infinity)
                }

                // MARK: Toggle Favorite

                ActionButton(
                    L10n.favorited,
                    icon: "heart",
                    selectedIcon: "heart.fill",
                    color: Color.red
                ) {
                    UIDevice.impact(.light)
                    viewModel.send(.toggleIsFavorite)
                }
                .environment(\.isSelected, viewModel.item.userData?.isFavorite == true)
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
                    TrailerMenu(viewModel: viewModel)
                        .if(equalSpacing) { view in
                            view.frame(maxWidth: .infinity)
                        }
                }
            }
        }
    }
}
