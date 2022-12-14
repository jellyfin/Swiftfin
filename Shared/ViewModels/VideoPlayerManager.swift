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
//            getAdjacentEpisodes(for: newValue.item)
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

    func onStateUpdated(state: VLCVideoPlayer.State, playbackInformation: VLCVideoPlayer.PlaybackInformation) {
        guard self.state != state else { return }
        self.state = state

        // TODO: Fix autoplay
        if state == .ended {
            if let nextViewModel,
               Defaults[.VideoPlayer.autoPlay],
               Defaults[.VideoPlayer.autoPlayEnabled] {
                selectNextViewModel()

                proxy.playNewMedia(nextViewModel.vlcVideoPlayerConfiguration)
            }
        }
    }
}

extension VideoPlayerManager {
    
    
    
}
