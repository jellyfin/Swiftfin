//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionButtonHStack: View {

        @ObservedObject
        var viewModel: ItemViewModel

        // TODO: Shrink to minWWith 100 (button) / 50 (menu) and 16 spacing to get 4 buttons inline
        var body: some View {
            HStack(alignment: .center, spacing: 24) {

                // MARK: - Toggle Played

                ActionButton(
                    title: L10n.played,
                    icon: "checkmark.circle",
                    selectedIcon: "checkmark.circle.fill"
                ) {
                    viewModel.send(.toggleIsPlayed)
                }
                .foregroundStyle(.purple)
                .environment(\.isSelected, viewModel.item.userData?.isPlayed ?? false)
                .frame(minWidth: 140, maxWidth: .infinity)

                // MARK: - Toggle Favorite

                ActionButton(
                    title: L10n.favorited,
                    icon: "heart.circle",
                    selectedIcon: "heart.circle.fill"
                ) {
                    viewModel.send(.toggleIsFavorite)
                }
                .foregroundStyle(.pink)
                .environment(\.isSelected, viewModel.item.userData?.isFavorite ?? false)
                .frame(minWidth: 140, maxWidth: .infinity)

                // MARK: - Additional Menu Options

                // TODO: Enable if there are more items needed
                /* ActionMenu {}
                 .frame(width: 70)*/
            }
            .frame(height: 100)
        }
    }
}
