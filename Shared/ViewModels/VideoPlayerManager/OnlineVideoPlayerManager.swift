//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class OnlineVideoPlayerManager: VideoPlayerManager {

    init(item: BaseItemDto, mediaSource: MediaSourceInfo) {
        super.init()

        Task {
            let viewModel = try await item.videoPlayerViewModel(with: mediaSource)

            await MainActor.run {
                self.currentViewModel = viewModel
            }
        }
    }
}
