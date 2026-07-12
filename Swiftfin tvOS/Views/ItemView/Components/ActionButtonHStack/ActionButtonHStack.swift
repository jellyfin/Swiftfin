//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionButtonHStack: View {

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        // MARK: - Observed, State, & Environment Objects

        @Router
        private var router

        @ObservedObject
        var provider: ItemContentGroupProvider

        // MARK: - Has Trailers

        private var hasTrailers: Bool {
            if enabledTrailers.contains(.local), provider.localTrailers.isNotEmpty {
                return true
            }

            if enabledTrailers.contains(.external), provider.item.remoteTrailers?.isNotEmpty == true {
                return true
            }

            return false
        }

        // MARK: - Body

        var body: some View {
            HStack(alignment: .center, spacing: 30) {

                // MARK: Toggle Played

                if provider.item.canBePlayed {
                    let isCheckmarkSelected = provider.item.userData?.isPlayed == true

                    Button(L10n.played, systemImage: "checkmark") {
                        Task { await provider.toggleIsPlayed() }
                    }
                    .labelStyle(.tintedMaterial(tint: Color.jellyfinPurple, foregroundColor: .primary))
                    .isSelected(isCheckmarkSelected)
                    .frame(minWidth: 100, maxWidth: .infinity)
                }

                // MARK: Toggle Favorite

                let isHeartSelected = provider.item.userData?.isFavorite == true

                Button(L10n.favorited, systemImage: isHeartSelected ? "heart.fill" : "heart") {
                    Task { await provider.toggleIsFavorite() }
                }
                .labelStyle(.tintedMaterial(tint: .pink, foregroundColor: .primary))
                .isSelected(isHeartSelected)
                .frame(minWidth: 100, maxWidth: .infinity)

                // MARK: Watch a Trailer

                if hasTrailers {
                    TrailerMenu(
                        localTrailers: provider.localTrailers,
                        externalTrailers: provider.item.remoteTrailers ?? []
                    )
                    .labelStyle(.tintedMaterial(tint: .pink, foregroundColor: .primary))
                    .frame(minWidth: 100, maxWidth: .infinity)
                }

                // MARK: Advanced Options

                if provider.item.showEditorMenu {
                    Menu {
                        ItemEditorMenu(item: provider.item)
                    } label: {
                        Label(L10n.advanced, systemImage: "ellipsis")
                            .rotationEffect(.degrees(90))
                    }
                    .labelStyle(.tintedMaterial(tint: .clear, foregroundColor: .primary))
                    .frame(width: 60, height: 100)
                }
            }
            .frame(height: 100)
            .labelStyle(.iconOnly)
            .buttonStyle(_BasicHoverButtonStyle())
            .font(.title3)
            .fontWeight(.semibold)
        }
    }
}
