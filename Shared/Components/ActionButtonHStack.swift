//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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

    let item: BaseItemDto
    let localTrailers: [BaseItemDto]

    var body: some View {
        HStack(alignment: .center, spacing: 10) {

            if item.canBePlayed {

                let isPlayedSelected = item.userData?.isPlayed == true

                Button(L10n.played, systemImage: "checkmark") {
                    print("Mark as played action")
                }
                .foregroundStyle(.white, Color.jellyfinPurple)
                .isHighlighted(isPlayedSelected)
                .frame(maxWidth: .infinity)
            }

            let isFavoriteSelected = item.userData?.isFavorite == true

            Button(L10n.favorite, systemImage: isFavoriteSelected ? "heart.fill" : "heart") {
                print("Favorite action")
            }
            .foregroundStyle(.white, .red)
            .isHighlighted(isFavoriteSelected)
            .frame(maxWidth: .infinity)

            TrailerMenu(
                localTrailers: enabledTrailers.contains(.local) ? localTrailers : [],
                remoteTrailers: enabledTrailers.contains(.external) ? (item.remoteTrailers ?? []) : []
            )
            .menuStyle(.button)
            .foregroundStyle(.white)
            .isHighlighted(false)
            .frame(maxWidth: .infinity)

            if UIDevice.isTV {
                Menu {
                    Section {
                        Button(L10n.delete) {}
                        Button(L10n.edit) {}
                    }
                } label: {
                    Label {
                        Text(L10n.advanced)
                    } icon: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                    }
                }
                .menuStyle(.button)
                .foregroundStyle(.black, .white)
                .frame(width: 60)
            }
        }
        .font(.title3)
        .fontWeight(.semibold)
        .labelStyle(ActionLabelStyle())
        .buttonStyle(_BasicHoverButtonStyle())
        .frame(height: UIDevice.isTV ? 100 : 44)
        .withViewContext(.isOverComplexContent)
    }
}
