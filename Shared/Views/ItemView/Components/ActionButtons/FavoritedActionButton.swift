//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemActionButtons {

    struct Favorited: View {

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        private var isFavorited: Bool {
            provider.item.userData?.isFavorite == true
        }

        private var systemImage: String {
            if isFavorited {
                ItemActionButton.favorited.systemImage
            } else {
                ItemActionButton.favorited.secondarySystemImage
            }
        }

        var body: some View {
            Button(
                isFavorited ? L10n.removeFromFavorites : L10n.addToFavorites,
                systemImage: systemImage
            ) {
                Task { await provider.toggleIsFavorite() }
            }
            .isSelected(isFavorited)
        }
    }
}
