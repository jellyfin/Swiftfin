//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// TODO: the video player needs to be slightly refactored anyways, so I'm fine
//       with the channel retrieving method below and is mainly just for reference
//       for how I should probably handle getting the channels of programs elsewhere.

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

    init(program: BaseItemDto) {
        super.init()

        Task {
            guard let channel = try? await self.getChannel(for: program), let mediaSource = channel.mediaSources?.first else {
                assertionFailure("No channel for program?")
                return
            }

            let viewModel = try await program.liveVideoPlayerViewModel(with: mediaSource, logger: logger)

            await MainActor.run {
                self.currentViewModel = viewModel
            }
        }
    }

    private func getChannel(for program: BaseItemDto) async throws -> BaseItemDto? {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.ids = [program.channelID ?? ""]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items?.first
    }
}
