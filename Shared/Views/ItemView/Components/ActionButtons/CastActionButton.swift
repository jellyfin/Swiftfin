//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemActionButtons {

    struct Cast: View {

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        @Router
        private var router

        @StateObject
        private var viewModel = CastViewModel()

        private var isPlaying: Bool {
            viewModel.isPlaying(item: provider.item)
        }

        private var systemImage: String {
            if isPlaying {
                ItemActionButton.cast.systemImage
            } else {
                ItemActionButton.cast.secondarySystemImage
            }
        }

        var body: some View {
            Button(
                ItemActionButton.cast.displayTitle,
                systemImage: systemImage
            ) {
                guard let mediaPlayerItemProvider = provider.mediaPlayerItemProvider else { return }
                router.route(to: .remoteControl(provider: mediaPlayerItemProvider))
            }
            .isSelected(isPlaying)
            .onFirstAppear {
                viewModel.refresh()
            }
        }
    }
}
