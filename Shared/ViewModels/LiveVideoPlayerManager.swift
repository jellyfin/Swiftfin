//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

class LiveVideoPlayerManager: VideoPlayerManager {

    @Published
    var program: ChannelProgram?

    init(item: BaseItemDto, mediaSource: MediaSourceInfo, program: ChannelProgram? = nil) {
        self.program = program
        super.init()

        Task {
            let viewModel = try await item.liveVideoPlayerViewModel(with: mediaSource, logger: logger)

            await MainActor.run {
                self.currentViewModel = viewModel
            }
        }
    }
}
