//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// TODO: find some other name

struct ActionButtonHStack: View {

    @Environment(\.favoriteItemAction)
    private var favoriteItemAction

    @StoredValue(.User.enabledTrailers)
    private var enabledTrailers: TrailerSelection

    @ObservedObject
    var viewModel: _ItemViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 10) {

            if viewModel.item.canBePlayed {

                let isPlayedSelected = viewModel.item.userData?.isPlayed == true

                Button(L10n.played, systemImage: "checkmark") {
                    viewModel.item.userData?.isPlayed?.toggle()
                }
                .foregroundStyle(.white, Color.jellyfinPurple)
                .buttonStyle(.primary)
                .isHighlighted(isPlayedSelected)
                .frame(maxWidth: .infinity)
            }

            let isFavoriteSelected = viewModel.item.userData?.isFavorite == true

            Button(L10n.favorite, systemImage: isFavoriteSelected ? "heart.fill" : "heart") {
                viewModel.item.userData?.isFavorite?.toggle()
            }
            .foregroundStyle(.white, .red)
            .buttonStyle(.primary)
            .isHighlighted(isFavoriteSelected)
            .frame(maxWidth: .infinity)

            TrailerMenu(
                localTrailers: enabledTrailers.contains(.local) ? viewModel.localTrailers : [],
                remoteTrailers: enabledTrailers.contains(.external) ? (viewModel.item.remoteTrailers ?? []) : []
            )
            .menuStyle(.button)
            .foregroundStyle(.black, .white)
            .buttonStyle(.primary)
            .frame(maxWidth: .infinity)

            if UIDevice.isTV {
                Menu {
                    Section {
                        Button(L10n.delete) {}
                        Button(L10n.edit) {}
                    }
                } label: {
                    Label(L10n.advanced, systemImage: "ellipsis")
                        .rotationEffect(.degrees(90))
                }
                .buttonStyle(.primary)
                .frame(width: 60)
            }
        }
        .font(.title3)
        .fontWeight(.semibold)
        .labelStyle(.iconOnly)
        .frame(height: UIDevice.isTV ? 100 : 44)
        .withViewContext(.isOverComplexContent)
    }
}
