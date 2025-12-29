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

// TODO: find some other name

struct ActionButtonHStack: View {

    @StoredValue(.User.enabledTrailers)
    private var enabledTrailers: TrailerSelection

    @ObservedObject
    var viewModel: _ItemViewModel

    private var hasTrailers: Bool {
//            if enabledTrailers.contains(.local), viewModel.localTrailers.isNotEmpty {
//                return true
//            }
//
//            if enabledTrailers.contains(.external), viewModel.item.remoteTrailers?.isNotEmpty == true {
//                return true
//            }

        false
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {

            if viewModel.item.canBePlayed {

                let isPlayedSelected = viewModel.item.userData?.isPlayed == true

                Button(L10n.played, systemImage: "checkmark") {}
                    .buttonStyle(.tintedMaterial(tint: .jellyfinPurple, foregroundColor: .white))
                    .isSelected(isPlayedSelected)
                    .frame(maxWidth: .infinity)
            }

            let isFavoriteSelected = viewModel.item.userData?.isFavorite == true

            Button(L10n.favorite, systemImage: isFavoriteSelected ? "heart.fill" : "heart") {}
                .buttonStyle(.tintedMaterial(tint: .red, foregroundColor: .white))
                .isSelected(isFavoriteSelected)
                .frame(maxWidth: .infinity)

            TrailerMenu(
                item: viewModel.item
            )
            .menuStyle(.button)
            .frame(maxWidth: .infinity)

            #if os(tvOS)
            Menu {
                Section {
                    Button(L10n.delete) {}
                    Button(L10n.edit) {}
                }
            } label: {
                Label(L10n.advanced, systemImage: "ellipsis")
                    .rotationEffect(.degrees(90))
            }
            .buttonStyle(.material)
            .frame(width: 60)
            #endif
        }
        .font(.title3)
        .fontWeight(.semibold)
        .buttonStyle(.material)
        .labelStyle(.iconOnly)
        .frame(height: UIDevice.isTV ? 100 : 44)
    }
}
