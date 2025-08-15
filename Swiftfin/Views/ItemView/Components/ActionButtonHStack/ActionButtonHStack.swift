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

                if viewModel.item.canBePlayed {

                    // MARK: - Toggle Played

                    let isCheckmarkSelected = viewModel.item.userData?.isPlayed == true

                    Button(L10n.played, systemImage: "checkmark") {
                        viewModel.send(.toggleIsPlayed)
                    }
                    .buttonStyle(.tintedMaterial(tint: .jellyfinPurple, foregroundColor: .white))
                    .isSelected(isCheckmarkSelected)
                    .frame(maxWidth: .infinity)
                    .if(!equalSpacing) { view in
                        view.aspectRatio(1, contentMode: .fit)
                    }
                }

                // MARK: - Toggle Favorite

                let isHeartSelected = viewModel.item.userData?.isFavorite == true

                Button(L10n.favorite, systemImage: isHeartSelected ? "heart.fill" : "heart") {
                    viewModel.send(.toggleIsFavorite)
                }
                .buttonStyle(.tintedMaterial(tint: .red, foregroundColor: .white))
                .isSelected(isHeartSelected)
                .frame(maxWidth: .infinity)
                .if(!equalSpacing) { view in
                    view.aspectRatio(1, contentMode: .fit)
                }

                // MARK: - Select a Version

                if let mediaSources = viewModel.playButtonItem?.mediaSources,
                   mediaSources.count > 1
                {
                    VersionMenu(
                        viewModel: viewModel,
                        mediaSources: mediaSources
                    )
                    .menuStyle(.button)
                    .frame(maxWidth: .infinity)
                    .if(!equalSpacing) { view in
                        view.aspectRatio(1, contentMode: .fit)
                    }
                }

                // MARK: - Watch a Trailer

                if hasTrailers {
                    TrailerMenu(
                        localTrailers: viewModel.localTrailers,
                        externalTrailers: viewModel.item.remoteTrailers ?? []
                    )
                    .menuStyle(.button)
                    .frame(maxWidth: .infinity)
                    .if(!equalSpacing) { view in
                        view.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .font(.title3)
            .fontWeight(.semibold)
            .buttonStyle(.material)
            .labelStyle(.iconOnly)
        }
    }
}
