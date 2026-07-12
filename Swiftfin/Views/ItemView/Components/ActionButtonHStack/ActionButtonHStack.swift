//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct ActionButtonHStack: View {

        @Default(.accentColor)
        private var accentColor

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        @ObservedObject
        var provider: ItemContentGroupProvider

        private var hasTrailers: Bool {
            if enabledTrailers.contains(.local), provider.localTrailers.isNotEmpty {
                return true
            }

            if enabledTrailers.contains(.external), provider.item.remoteTrailers?.isNotEmpty == true {
                return true
            }

            return false
        }

        var body: some View {
            HStack(alignment: .center, spacing: 10) {

                if provider.item.canBePlayed {

                    // MARK: - Toggle Played

                    let isCheckmarkSelected = provider.item.userData?.isPlayed == true

                    Button(L10n.played, systemImage: "checkmark") {
                        Task { await provider.toggleIsPlayed() }
                    }
                    .foregroundStyle(.primary, .secondary)
                    .labelStyle(.tintedMaterial(tint: .jellyfinPurple, foregroundColor: .white))
                    .isSelected(isCheckmarkSelected)
                    .frame(maxWidth: .infinity)
                }

                // MARK: - Toggle Favorite

                let isHeartSelected = provider.item.userData?.isFavorite == true

                Button(L10n.favorite, systemImage: isHeartSelected ? "heart.fill" : "heart") {
                    Task { await provider.toggleIsFavorite() }
                }
                .foregroundStyle(.primary, .secondary)
                .labelStyle(.tintedMaterial(tint: .red, foregroundColor: .white))
                .isSelected(isHeartSelected)
                .frame(maxWidth: .infinity)

                // MARK: - Select a Version

                if let mediaSources = provider.playButtonItem?.mediaSources,
                   mediaSources.count > 1
                {
                    VersionMenu(
                        provider: provider,
                        mediaSources: mediaSources
                    )
                    .menuStyle(.button)
                    .foregroundStyle(.primary, .secondary)
                    .labelStyle(.tintedMaterial(tint: .clear, foregroundColor: .primary))
                    .frame(maxWidth: .infinity)
                }

                // MARK: - Watch a Trailer

                if hasTrailers {
                    TrailerMenu(
                        localTrailers: provider.localTrailers,
                        externalTrailers: provider.item.remoteTrailers ?? []
                    )
                    .menuStyle(.button)
                    .foregroundStyle(.primary, .secondary)
                    .labelStyle(.tintedMaterial(tint: .clear, foregroundColor: .primary))
                    .frame(maxWidth: .infinity)
                }
            }
            .font(.title3)
            .fontWeight(.semibold)
            .buttonStyle(.card)
//            .buttonStyle(_BasicHoverButtonStyle())
            .labelStyle(.iconOnly)
        }
    }
}
