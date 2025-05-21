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

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        @ObservedObject
        private var viewModel: ItemViewModel

        @EnvironmentObject
        private var router: MainCoordinator.Router

        private let equalSpacing: Bool

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
        }

        // MARK: - Body

        var body: some View {
            HStack(alignment: .center, spacing: 10) {

                // MARK: Toggle Played

                let isCheckmarkSelected = viewModel.item.userData?.isPlayed == true

                ActionButton(
                    L10n.played,
                    icon: "checkmark.circle",
                    selectedIcon: "checkmark.circle.fill",
                    buttonColor: accentColor
                ) {
                    UIDevice.impact(.light)
                    viewModel.send(.toggleIsPlayed)
                }
                .environment(\.isSelected, isCheckmarkSelected)
                .if(equalSpacing) { view in
                    view.frame(maxWidth: .infinity)
                }
                .if(!equalSpacing) { view in
                    view.aspectRatio(1, contentMode: .fit)
                }

                // MARK: Toggle Favorite

                let isHeartSelected = viewModel.item.userData?.isFavorite == true

                ActionButton(
                    L10n.favorited,
                    icon: "heart",
                    selectedIcon: "heart.fill",
                    buttonColor: .pink
                ) {
                    UIDevice.impact(.light)
                    viewModel.send(.toggleIsFavorite)
                }
                .environment(\.isSelected, isHeartSelected)
                .if(equalSpacing) { view in
                    view.frame(maxWidth: .infinity)
                }
                .if(!equalSpacing) { view in
                    view.aspectRatio(1, contentMode: .fit)
                }

                // MARK: Select a Version

                if let mediaSources = viewModel.playButtonItem?.mediaSources,
                   mediaSources.count > 1
                {
                    VersionMenu(viewModel: viewModel, mediaSources: mediaSources)
                        .if(equalSpacing) { view in
                            view.frame(maxWidth: .infinity)
                        }
                        .if(!equalSpacing) { view in
                            view.aspectRatio(1, contentMode: .fit)
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
                    .if(!equalSpacing) { view in
                        view.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
}
