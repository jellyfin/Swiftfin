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
import VLCUI

// TODO: Make online/offline

class VideoPlayerManager: ViewModel {
    
    @Default(.VideoPlayer.autoPlay)
    private var autoPlay
    @Default(.VideoPlayer.autoPlayEnabled)
    private var autoPlayEnabled
    
    @RouterObject
    private var router: ItemVideoPlayerCoordinator.Router?

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
    var currentViewModel: VideoPlayerViewModel? {
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
        
        item.createVideoPlayerViewModel(with: mediaSource)
            .sink { completion in
                self.handleAPIRequestError(completion: completion)
            } receiveValue: { viewModel in
                self.currentViewModel = viewModel
            }
            .store(in: &cancellables)
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

extension VideoPlayerManager {
    func getAdjacentEpisodes(for item: BaseItemDto) {
        guard let seriesID = item.seriesId, item.type == .episode else { return }

        TvShowsAPI.getEpisodes(
            seriesId: seriesID,
            userId: SessionManager.main.currentLogin.user.id,
            fields: ItemFields.minimumCases,
            adjacentTo: item.id,
            limit: 3
        )
        .sink(receiveCompletion: { completion in
            self.handleAPIRequestError(completion: completion)
        }, receiveValue: { response in

            // 4 possible states:
            //  1 - only current episode
            //  2 - two episodes with next episode
            //  3 - two episodes with previous episode
            //  4 - three episodes with current in middle

            // State 1
            guard let items = response.items, items.count > 1 else { return }

            if items.count == 2 {
                if items[0].id == item.id {
                    // State 2
                    let nextItem = items[1]

                    nextItem.createItemVideoPlayerViewModel()
                        .sink { completion in
                            print(completion)
                        } receiveValue: { viewModels in
                            self.nextViewModel = viewModels.first
                        }
                        .store(in: &self.cancellables)
                } else {
                    // State 3
                    let previousItem = items[0]

                    previousItem.createItemVideoPlayerViewModel()
                        .sink { completion in
                            print(completion)
                        } receiveValue: { viewModels in
                            self.previousViewModel = viewModels.first
                        }
                        .store(in: &self.cancellables)
                }
            } else {
                // State 4

                let previousItem = items[0]
                let nextItem = items[2]

                previousItem.createItemVideoPlayerViewModel()
                    .sink { completion in
                        print(completion)
                    } receiveValue: { viewModels in
                        self.previousViewModel = viewModels.first
                    }
                    .store(in: &self.cancellables)

                nextItem.createItemVideoPlayerViewModel()
                    .sink { completion in
                        print(completion)
                    } receiveValue: { viewModels in
                        self.nextViewModel = viewModels.first
                    }
                    .store(in: &self.cancellables)
            }
        })
        .store(in: &cancellables)
    }
}
