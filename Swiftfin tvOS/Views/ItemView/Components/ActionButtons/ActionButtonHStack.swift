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

        var body: some View {
            HStack(alignment: .center) {

                // Spacer()

                // MARK: - Toggle Played

                ActionButton(
                    icon: "checkmark.circle",
                    selectedIcon: "checkmark.circle.fill",
                    color: Color.jellyfinPurple
                ) {
                    viewModel.send(.toggleIsPlayed)
                }
                .environment(\.isSelected, viewModel.item.userData?.isPlayed == true)
                .frame(height: 100)
                .frame(maxWidth: .infinity)

                // Spacer()

                // MARK: - Toggle Favorite

                ActionButton(
                    icon: "heart.circle",
                    selectedIcon: "heart.circle.fill",
                    color: .pink
                ) {
                    viewModel.send(.toggleIsFavorite)
                }
                .environment(\.isSelected, viewModel.item.userData?.isFavorite ?? false)
                .frame(height: 100)
                .frame(maxWidth: .infinity)

                // Spacer()
            }
        }
    }
}
