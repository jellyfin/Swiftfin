//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Logging

extension ItemViewModel {

    func playShuffle(router: NavigationCoordinator.Router) {
        guard item.canShuffle else {
            logger.error("Shuffle not supported for item type: \(String(describing: item.type))")
            return
        }

        Task { @MainActor in
            do {
                #if os(tvOS)
                let autoSelectMediaSource = false
                #else
                let autoSelectMediaSource = true
                #endif

                try await ShuffleActionHelper().shuffleAndPlay(
                    item,
                    viewModel: self,
                    router: router,
                    autoSelectMediaSource: autoSelectMediaSource
                )
            } catch {
                logger.error("Error shuffling items: \(error)")
            }
        }
    }
}
