//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Logging

final class OnlineVideoPlayerManager: VideoPlayerManager {

    private let item: BaseItemDto
    private let mediaSource: MediaSourceInfo

    init(item: BaseItemDto, mediaSource: MediaSourceInfo) {
        self.item = item
        self.mediaSource = mediaSource
        super.init()

        Task {
            // Select the best audio stream based on the media source
            let bestAudioStreamIndex = mediaSource.selectBestAudioStreamIndex()

            logger.debug("Initial load - selecting audio stream index: \(bestAudioStreamIndex)")

            await updateViewModel(for: bestAudioStreamIndex >= 0 ? bestAudioStreamIndex : nil)
        }
    }

    /// Switches to a different audio track by re-requesting playback info from the server
    func switchAudioTrack(to audioStreamIndex: Int) {
        Task {
            logger.debug("Switching audio track to index: \(audioStreamIndex)")
            await updateViewModel(for: audioStreamIndex)
        }
    }

    private func updateViewModel(for audioStreamIndex: Int?) async {
        do {
            let viewModel = try await item.videoPlayerViewModel(with: mediaSource, audioStreamIndex: audioStreamIndex)
            await MainActor.run {
                self.currentViewModel = viewModel
            }
        } catch {
            logger.error("Failed to update video player view model: \(error)")
        }
    }
}
