//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Logging
import SwiftUI

extension ItemView {

    struct OptionsMenu: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: ItemViewModel

        private let logger = Logger.swiftfin()

        // MARK: - Body

        var body: some View {
            Menu {
                Button(L10n.shuffle, systemImage: "shuffle") {
                    playShuffle()
                }
            } label: {
                Label(L10n.options, systemImage: "ellipsis.circle")
            }
        }

        // MARK: - Play Shuffled

        private func playShuffle() {
            guard viewModel.item.canShuffle else {
                logger.error("Shuffle not supported for item type: \(String(describing: viewModel.item.type))")
                return
            }

            Task {
                do {
                    try await ShuffleActionHelper().shuffleAndPlayWithAutoSource(
                        viewModel.item,
                        viewModel: viewModel,
                        router: router.router
                    )
                } catch {
                    logger.error("Error shuffling items: \(error)")
                }
            }
        }
    }
}
