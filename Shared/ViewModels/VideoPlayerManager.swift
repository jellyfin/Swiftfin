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

class VideoPlayerManager: ViewModel {
    
    // Used for accessing live playback information and
    // updating only the views that request it
    class CurrentPlaybackInformation: ObservableObject {

        @Published
        var currentSeconds: Int = 0
        @Published
        var playbackInformation: VLCVideoPlayer.PlaybackInformation?

        func onTicksUpdated(ticks: Int, playbackInformation: VLCVideoPlayer.PlaybackInformation) {
            self.currentSeconds = ticks / 1000
            self.playbackInformation = playbackInformation
        }
    }
    
    @Default(.VideoPlayer.autoPlay)
    private var autoPlay
    @Default(.VideoPlayer.autoPlayEnabled)
    private var autoPlayEnabled
    
    @Injected(PlaybackManager.service)
    private var playbackManager
    
    @RouterObject
    private var router: ItemVideoPlayerCoordinator.Router?

    // MARK: Properties

    @Published
    var audioTrackIndex: Int = -1
    @Published
    var rate: Float = 1
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
    
    private let playstateTimer: TimerProxy = .init()
    let proxy: VLCVideoPlayer.Proxy = .init()

    // MARK: init

    init(viewModel: VideoPlayerViewModel) {
        self.currentViewModel = viewModel
        super.init()
        
        getAdjacentEpisodes(for: viewModel.item)
    }

    init(item: BaseItemDto) {
        super.init()
        item.createItemVideoPlayerViewModel()
            .sink { completion in
                self.handleAPIRequestError(completion: completion)
            } receiveValue: { viewModels in
                self.currentViewModel = viewModels[0]
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
            print("Current audio track index: \(playbackInformation.currentAudioTrack.index)")
        }

        if rate != playbackInformation.playbackRate {
            self.rate = playbackInformation.playbackRate
        }

        if subtitleTrackIndex != playbackInformation.currentSubtitleTrack.index {
            subtitleTrackIndex = playbackInformation.currentSubtitleTrack.index
        }
    }

    func onStateUpdated(state: VLCVideoPlayer.State, playbackInformation: VLCVideoPlayer.PlaybackInformation) {
        guard self.state != state else { return }
        self.state = state
        
        if state == .buffering ||
            state == .paused {
            
        }
        
        if state == .stopped {
            if let nextViewModel,
               autoPlay,
               autoPlayEnabled {
                selectNextViewModel()
                
                proxy.playNewMedia(nextViewModel.configuration)
            } else {
                router?.dismissCoordinator()
            }
        }
    }
}

extension VideoPlayerManager {
    func getAdjacentEpisodes(for item: BaseItemDto) {
        guard let seriesID = item.seriesId, item.type == .episode else { return }

        TvShowsAPI.getEpisodes(
            seriesId: seriesID,
            userId: SessionManager.main.currentLogin.user.id,
            fields: [.chapters],
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
