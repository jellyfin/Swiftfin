//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct ActionButtonHStack: View {

        @Default(.accentColor)
        private var accentColor

        @Default(.isLiquidGlassEnabled)
        private var isLiquidGlassEnabled

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        @ObservedObject
        var viewModel: ItemViewModel

        var equalSpacing: Bool = true

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

        // MARK: - Body

        var body: some View {
            HStack(alignment: .center, spacing: 10) {

                if viewModel.item.canBePlayed {

                    // MARK: - Toggle Played

                    let isCheckmarkSelected = viewModel.item.userData?.isPlayed == true

                    if isLiquidGlassEnabled, #available(iOS 26.0, *) {
                        Toggle(L10n.played, systemImage: "checkmark", isOn: Binding(get: {
                            isCheckmarkSelected
                        }, set: { _ in
                            viewModel.send(.toggleIsPlayed)
                        })).toggleStyle(.button).tint(.jellyfinPurple).buttonStyle(.glass)
                            .if(!equalSpacing) { view in
                                view.aspectRatio(1, contentMode: .fit)
                            }
                    } else {
                        Button(L10n.played, systemImage: "checkmark") {
                            viewModel.send(.toggleIsPlayed)
                        }
                        .isSelected(isCheckmarkSelected)
                        .frame(minWidth: 100, maxWidth: .infinity)
                        .buttonStyle(.tintedMaterial(tint: .jellyfinPurple, foregroundColor: .primary))
                    }
                }

                // MARK: - Toggle Favorite

                let isHeartSelected = viewModel.item.userData?.isFavorite == true

                if isLiquidGlassEnabled, #available(iOS 26.0, *) {
                    Toggle(L10n.favorite, systemImage: "heart.fill", isOn: Binding(get: {
                        isHeartSelected
                    }, set: { _ in
                        viewModel.send(.toggleIsFavorite)
                    })).toggleStyle(.button).tint(.red).buttonStyle(.glass)
                        .if(!equalSpacing) { view in
                            view.aspectRatio(1, contentMode: .fit)
                        }
                } else {
                    Button(L10n.favorite, systemImage: isHeartSelected ? "heart.fill" : "heart") {
                        viewModel.send(.toggleIsFavorite)
                    }
                    .buttonStyle(.tintedMaterial(tint: .red, foregroundColor: .white))
                    .isSelected(isHeartSelected)
                    .frame(maxWidth: .infinity)
                    .if(!equalSpacing) { view in
                        view.aspectRatio(1, contentMode: .fit)
                    }
                }

                // MARK: - Select a Version

                if let mediaSources = viewModel.playButtonItem?.mediaSources,
                   mediaSources.count > 1
                {
                    let versionMenu = VersionMenu(
                        viewModel: viewModel,
                        mediaSources: mediaSources
                    )
                    .menuStyle(.button)
                    .if(!equalSpacing) { view in
                        view.aspectRatio(1, contentMode: .fit)
                    }

                    if isLiquidGlassEnabled, #available(iOS 26.0, *) {
                        versionMenu.buttonStyle(.glass)
                    } else {
                        versionMenu
                            .frame(maxWidth: .infinity)
                    }
                }

                // MARK: - Watch a Trailer

                if hasTrailers {
                    let trailersMenu = TrailerMenu(
                        localTrailers: viewModel.localTrailers,
                        externalTrailers: viewModel.item.remoteTrailers ?? []
                    )
                    .menuStyle(.button)
                    .if(!equalSpacing) { view in
                        view.aspectRatio(1, contentMode: .fit)
                    }

                    if isLiquidGlassEnabled, #available(iOS 26.0, *) {
                        trailersMenu.buttonStyle(.glass)
                    } else {
                        trailersMenu
                            .frame(maxWidth: .infinity)
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
