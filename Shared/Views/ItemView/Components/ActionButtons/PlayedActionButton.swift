//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemActionButtons {

    struct Played: View {

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        private var isPlayed: Bool {
            provider.item.userData?.isPlayed == true
        }

        var body: some View {
            Button(
                isPlayed ? L10n.markAsUnplayed : L10n.markAsPlayed,
                systemImage: ItemActionButton.played.systemImage
            ) {
                Task { await provider.toggleIsPlayed() }
            }
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary, .secondary)
            .isSelected(isPlayed)
        }
    }
}
