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
            HStack {
                ActionButton(
                    inactiveImage: "checkmark.circle",
                    activeImage: "checkmark.circle.fill",
                    activeColor: Color.jellyfinPurple
                ) {
                    viewModel.send(.toggleIsPlayed)
                }
                .environment(\.isSelected, viewModel.item.userData?.isPlayed == true)

                Spacer()

                ActionButton(
                    inactiveImage: "heart.circle",
                    activeImage: "heart.circle.fill",
                    activeColor: .pink
                ) {
                    viewModel.send(.toggleIsFavorite)
                }
                .environment(\.isSelected, viewModel.item.userData?.isFavorite == true)
            }
        }
    }
}
