//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI
import Stinsen
import UIKit
import VLCUI

// TODO: Make online/offline
// TODO: proper error catching

class VideoPlayerManager: ViewModel {

    @Published
    var audioTrackIndex: Int = -1
    @Published
    var playbackSpeed: Float = 1
    @Published
    var state: VLCVideoPlayer.State = .opening
    @Published
    var subtitleTrackIndex: Int = -1

    // MARK: ViewModel

    @Published
    var previousViewModel: VideoPlayerViewModel?
    @Published
    var currentViewModel: VideoPlayerViewModel! {
        willSet {
            guard let newValue else { return }
            getAdjacentEpisodes(for: newValue.item)
        }
    }

    @Published
    var nextViewModel: VideoPlayerViewModel?

    let proxy: VLCVideoPlayer.Proxy = .init()

    // MARK: init

    init(item: BaseItemDto, mediaSource: MediaSourceInfo) {
        super.init()

        Task {
            let viewModel = try await item.videoPlayerViewModel(with: mediaSource)

            await MainActor.run {
                self.currentViewModel = viewModel
            }
        }
    }

    func selectNextViewModel() {
        guard let nextViewModel else { return }
        currentViewModel = nextViewModel
        previousViewModel = nil
        self.nextViewModel = nil
    }

    func selectPreviousViewModel() {
        guard let previousViewModel else { return }
        currentViewModel = previousViewModel
        self.previousViewModel = nil
        nextViewModel = nil
    }

    func onTicksUpdated(ticks: Int, playbackInformation: VLCVideoPlayer.PlaybackInformation) {

        if audioTrackIndex != playbackInformation.currentAudioTrack.index {
            audioTrackIndex = playbackInformation.currentAudioTrack.index
        }

        if playbackSpeed != playbackInformation.playbackRate {
            self.playbackSpeed = playbackInformation.playbackRate
        }

        if subtitleTrackIndex != playbackInformation.currentSubtitleTrack.index {
            subtitleTrackIndex = playbackInformation.currentSubtitleTrack.index
        }
    }

    func onStateUpdated(newState: VLCVideoPlayer.State, playbackInformation: VLCVideoPlayer.PlaybackInformation) {
        guard state != newState else { return }
        state = newState

        if newState == .ended {
            print("state ended")
            if let nextViewModel,
               Defaults[.VideoPlayer.autoPlay],
               Defaults[.VideoPlayer.autoPlayEnabled]
            {
                selectNextViewModel()

                proxy.playNewMedia(nextViewModel.vlcVideoPlayerConfiguration)
            }
        }
    }
}

extension VideoPlayerManager {

    func getAdjacentEpisodes(for item: BaseItemDto) {
        Task { @MainActor in
            guard let seriesID = item.seriesID, item.type == .episode else { return }

            let parameters = Paths.GetEpisodesParameters(
                userID: userSession.user.id,
                fields: ItemFields.minimumCases,
                adjacentTo: item.id!,
                limit: 3
            )
            let request = Paths.getEpisodes(seriesID: seriesID, parameters: parameters)
            let response = try await userSession.client.send(request)

            // 4 possible states:
            //  1 - only current episode
            //  2 - two episodes with next episode
            //  3 - two episodes with previous episode
            //  4 - three episodes with current in middle

            // 1
            guard let items = response.value.items, items.count > 1 else { return }

            var previousItem: BaseItemDto?
            var nextItem: BaseItemDto?

            if items.count == 2 {
                if items[0].id == item.id {
                    // 2
                    nextItem = items[1]

                } else {
                    // 3
                    previousItem = items[0]
                }
            } else {
                nextItem = items[2]
                previousItem = items[0]
            }

            var nextViewModel: VideoPlayerViewModel?
            var previousViewModel: VideoPlayerViewModel?

            if let nextItem, let nextItemMediaSource = nextItem.mediaSources?.first {
                nextViewModel = try await nextItem.videoPlayerViewModel(with: nextItemMediaSource)
            }

            if let previousItem, let previousItemMediaSource = previousItem.mediaSources?.first {
                previousViewModel = try await previousItem.videoPlayerViewModel(with: previousItemMediaSource)
            }

            await MainActor.run {
                self.nextViewModel = nextViewModel
                self.previousViewModel = previousViewModel
            }
        }
    }
}
