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

    private let item: BaseItemDto
    private let mediaSource: MediaSourceInfo

    init(item: BaseItemDto, mediaSource: MediaSourceInfo) {
        self.item = item
        self.mediaSource = mediaSource
        super.init()

        Task {
            // Select the best audio stream based on the media source
            let bestAudioStreamIndex = mediaSource.selectBestAudioStreamIndex()

            print("[OnlineVideoPlayerManager] Initial load - selecting audio stream index: \(bestAudioStreamIndex)")

            let viewModel = try await item.videoPlayerViewModel(
                with: mediaSource,
                audioStreamIndex: bestAudioStreamIndex >= 0 ? bestAudioStreamIndex : nil
            )

            await MainActor.run {
                self.currentViewModel = viewModel
            }
        }
    }

    /// Switches to a different audio track by re-requesting playback info from the server
    func switchAudioTrack(to audioStreamIndex: Int) {
        Task {
            do {
                print("[OnlineVideoPlayerManager] Switching audio track to index: \(audioStreamIndex)")

                // Request new playback info with the selected audio stream
                let newViewModel = try await item.videoPlayerViewModel(with: mediaSource, audioStreamIndex: audioStreamIndex)

                await MainActor.run {
                    self.currentViewModel = newViewModel
                }
            } catch {
                print("[OnlineVideoPlayerManager] Failed to switch audio track: \(error)")
            }
        }
    }
}
