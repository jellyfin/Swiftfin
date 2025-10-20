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
            ActionButton(L10n.options, icon: "ellipsis.circle") {
                Button(L10n.shuffle, systemImage: "shuffle") {
                    playShuffle()
                }
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
                    let containerTypes: Set<BaseItemKind> = [.series, .boxSet, .collectionFolder, .folder, .playlist]
                    let helper = ShuffleActionHelper()

                    if let itemType = viewModel.item.type, containerTypes.contains(itemType) {
                        // Use a dummy media source for containers - it won't be used
                        try await helper.shuffleAndPlay(
                            viewModel.item,
                            mediaSource: MediaSourceInfo(),
                            viewModel: viewModel,
                            router: router.router
                        )
                    } else {
                        // For playable items, require media source
                        guard let selectedMediaSource = viewModel.selectedMediaSource else {
                            logger.error("Shuffle selected with no media source for playable item")
                            return
                        }

                        try await helper.shuffleAndPlay(
                            viewModel.item,
                            mediaSource: selectedMediaSource,
                            viewModel: viewModel,
                            router: router.router
                        )
                    }
                } catch {
                    logger.error("Error shuffling items: \(error)")
                }
            }
        }
    }
}
