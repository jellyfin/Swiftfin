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
import JellyfinAPILegacy
import Stinsen
import VLCUI
import UIKit

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
        
//        item.createVideoPlayerViewModel(with: mediaSource)
//            .sink { completion in
//                self.handleAPIRequestError(completion: completion)
//            } receiveValue: { viewModel in
//                self.currentViewModel = viewModel
//            }
//            .store(in: &cancellables)
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
//        if state == .stopped {
//            if let nextViewModel,
//               autoPlay,
//               autoPlayEnabled {
//                selectNextViewModel()
//
//                proxy.playNewMedia(nextViewModel.configuration)
//            }
//        }
    }
}
