//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Combine
import Defaults
import Factory
import Foundation
import JellyfinAPI
import MediaPlayer
import UIKit
import VLCUI

// TODO: better online/offline handling
// TODO: proper error catching
// TODO: better solution for previous/next/queuing
// TODO: should view models handle progress reports instead, with a protocol
//       for other types of media handling

protocol VideoPlayerListener {
    func stateDidChange(newState: VideoPlayerManager.State)
    func playbackTimeDidChange(newSeconds: Int)
}

// TODO: transition to `Stateful`
// TODO: make `Eventful`
//       - didEndQueue
// TODO: queue provider
class VideoPlayerManager: ViewModel, Eventful, Stateful {

    enum Event {
        case playbackStopped
        case playItem(VideoPlayerPlaybackItem)
    }

    enum Action: Equatable {

        case error(JellyfinAPIError)

        case pause
        case play
        case buffer
        case ended
        case stop

        case playNextItem
        case playPreviousItem
    }

    enum State: Hashable {
        case initial
        case loadingItem
        case error(JellyfinAPIError)

        case playing
        case paused
        case buffering
        case stopped
    }

    @Injected(\.nowPlayable)
    var nowPlayable: NowPlayable

    @Published
    private(set) var playbackItem: VideoPlayerPlaybackItem! = nil {
        didSet {
            guard let playbackItem else { return }
            eventSubject.send(.playItem(playbackItem))
        }
    }

    @Published
    private(set) var item: BaseItemDto

    @Published
    var progress: ProgressBox = .init(progress: 0, seconds: 0)
    @Published
    private(set) var queue: [BaseItemDto] = []
    @Published
    private(set) var playbackSpeed: PlaybackSpeed = .one

    @Published
    final var state: State = .initial
    @Published
    final var lastAction: Action? = nil

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private let eventSubject: PassthroughSubject<Event, Never> = .init()

    // proxy for the underlying video playing layer
    var proxy: VideoPlayerProxy!
    var itemBuildTask: AnyCancellable?

    // MARK: init

    // TODO: rename to `baseItem`
    init(
        item: BaseItemDto,
        mediaSource: MediaSourceInfo
    ) {
        self.item = item
        super.init()

        buildCurrentItem(with: item, mediaSource: mediaSource)
        queue.append(item)
    }

    init(playbackItem: VideoPlayerPlaybackItem) {
        item = playbackItem.baseItem
        super.init()

        self.playbackItem = playbackItem
        queue.append(playbackItem.baseItem)

        state = .buffering
    }

    @MainActor
    func respond(to action: Action) -> State {

        guard state != .stopped else { return .stopped }

        switch action {
        case let .error(error):
            return .error(error)
        case .pause:
            return .paused
        case .play:
            return .playing
        case .buffer:
            return .buffering
        case .ended:
            // TODO: go next in queue
            return .loadingItem
        case .stop:
            Task { @MainActor in
                eventSubject.send(.playbackStopped)
            }
            return .stopped
        case .playNextItem:
            // TODO: go next in queue
            return .loadingItem
        case .playPreviousItem:
            // TODO: go back in queue
            return .loadingItem
        }
    }

    private func buildCurrentItem(with item: BaseItemDto, mediaSource: MediaSourceInfo) {
        itemBuildTask?.cancel()

        itemBuildTask = Task { [weak self] in
            do {
                await MainActor.run { [weak self] in
                    self?.state = .loadingItem
                }

                let playbackItem = try await VideoPlayerPlaybackItem.build(
                    for: item,
                    mediaSource: mediaSource
                )

                guard let self else { return }

                await MainActor.run {
                    self.state = .buffering
                    self.playbackItem = playbackItem
                }
            } catch {
                guard let self, !Task.isCancelled else { return }

                await MainActor.run {
                    self.send(.error(.init(error.localizedDescription)))
                }
            }
        }
        .asAnyCancellable()
    }
}

// MARK: OLD

extension VideoPlayerManager {
//
//    class CurrentProgressHandler: ObservableObject {
//
//        @Published
//        var progress: CGFloat = 0
//        @Published
//        var scrubbedProgress: CGFloat = 0
//
//        @Published
//        var seconds: Int = 0
//        @Published
//        var scrubbedSeconds: Int = 0
//    }

    // MARK: select

//    func selectNextViewModel() {
//        guard let nextViewModel else { return }
//        currentViewModel = nextViewModel
//        previousViewModel = nil
//        self.nextViewModel = nil
//
//        nowPlayable.handleNowPlayableItemChange(
//            metadata: currentViewModel.nowPlayingMetadata
//        )
//    }
//
//    func selectPreviousViewModel() {
//        guard let previousViewModel else { return }
//        currentViewModel = previousViewModel
//        self.previousViewModel = nil
//        nextViewModel = nil
//
//        nowPlayable.handleNowPlayableItemChange(
//            metadata: currentViewModel.nowPlayingMetadata
//        )
//    }

    // MARK: onTicksUpdated

    func onTicksUpdated(ticks: Int, playbackInformation: VLCVideoPlayer.PlaybackInformation) {

//        if audioTrackIndex != playbackInformation.currentAudioTrack.index {
//            audioTrackIndex = playbackInformation.currentAudioTrack.index
//        }
//
//        if subtitleTrackIndex != playbackInformation.currentSubtitleTrack.index {
//            subtitleTrackIndex = playbackInformation.currentSubtitleTrack.index
//        }
//
//        nowPlayable.handleNowPlayablePlaybackChange(
//            playing: true,
//            metadata: .init(
//                rate: Float(playbackSpeed.rawValue),
//                position: Float(currentProgressHandler.seconds),
//                duration: Float(currentViewModel.item.runTimeSeconds)
//            )
//        )
    }

    // MARK: onStateUpdated

    func onStateUpdated(newState: VLCVideoPlayer.State) {
//        guard state != newState else { return }
//        state = newState

//        nowPlayable.handleNowPlayableItemChange(
//            metadata: currentViewModel.nowPlayingMetadata
//        )
//
//        if !hasSentStart, newState == .playing {
//            hasSentStart = true
//            sendStartReport()
//        }
//
//        if hasSentStart, newState == .paused {
//            hasSentStart = false
//            sendPauseReport()
//        }
//
//        if newState == .stopped || newState == .ended {
//            sendStopReport()
//        }
    }

//    func getAdjacentEpisodes(for item: BaseItemDto) {
//        Task { @MainActor in
//            guard let seriesID = item.seriesID, item.type == .episode else { return }
//
//            let parameters = Paths.GetEpisodesParameters(
//                userID: userSession.user.id,
//                fields: .MinimumFields,
//                adjacentTo: item.id!,
//                limit: 3
//            )
//            let request = Paths.getEpisodes(seriesID: seriesID, parameters: parameters)
//            let response = try await userSession.client.send(request)
//
//            // 4 possible states:
//            //  1 - only current episode
//            //  2 - two episodes with next episode
//            //  3 - two episodes with previous episode
//            //  4 - three episodes with current in middle
//
//            // 1
//            guard let items = response.value.items, items.count > 1 else { return }
//
//            var previousItem: BaseItemDto?
//            var nextItem: BaseItemDto?
//
//            if items.count == 2 {
//                if items[0].id == item.id {
//                    // 2
//                    nextItem = items[1]
//
//                } else {
//                    // 3
//                    previousItem = items[0]
//                }
//            } else {
//                nextItem = items[2]
//                previousItem = items[0]
//            }
//
//            var nextViewModel: VideoPlayerViewModel?
//            var previousViewModel: VideoPlayerViewModel?
//
//            if let nextItem, let nextItemMediaSource = nextItem.mediaSources?.first {
//                nextViewModel = try await nextItem.videoPlayerViewModel(with: nextItemMediaSource)
//            }
//
//            if let previousItem, let previousItemMediaSource = previousItem.mediaSources?.first {
//                previousViewModel = try await previousItem.videoPlayerViewModel(with: previousItemMediaSource)
//            }
//
//            await MainActor.run {
//                self.nextViewModel = nextViewModel
//                self.previousViewModel = previousViewModel
//            }
//        }
//    }

    // MARK: reports

//    func sendStartReport() {
//
//        #if DEBUG
//        guard Defaults[.sendProgressReports] else { return }
//        #endif
//
//        currentProgressWorkItem?.cancel()
//
//        logger.debug("sent start report")
//
//        Task {
//            let startInfo = PlaybackStartInfo(
//                audioStreamIndex: audioTrackIndex,
//                itemID: currentViewModel.item.id,
//                mediaSourceID: currentViewModel.mediaSource.id,
//                playbackStartTimeTicks: Int(Date().timeIntervalSince1970) * 10_000_000,
//                positionTicks: currentProgressHandler.seconds * 10_000_000,
//                sessionID: currentViewModel.playSessionID,
//                subtitleStreamIndex: subtitleTrackIndex
//            )
//
//            let request = Paths.reportPlaybackStart(startInfo)
//            let _ = try await userSession.client.send(request)
//
//            let progressTask = DispatchWorkItem {
//                self.sendProgressReport()
//            }
//
//            currentProgressWorkItem = progressTask
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: progressTask)
//        }
//    }
//
//    func sendStopReport() {
//
//        let ids = ["itemID": currentViewModel.item.id, "seriesID": currentViewModel.item.parentID]
//        Notifications[.itemMetadataDidChange].post(object: ids)
//
//        #if DEBUG
//        guard Defaults[.sendProgressReports] else { return }
//        #endif
//
//        logger.debug("sent stop report")
//
//        currentProgressWorkItem?.cancel()
//
//        Task {
//            let stopInfo = PlaybackStopInfo(
//                itemID: currentViewModel.item.id,
//                mediaSourceID: currentViewModel.mediaSource.id,
//                positionTicks: currentProgressHandler.seconds * 10_000_000,
//                sessionID: currentViewModel.playSessionID
//            )
//
//            let request = Paths.reportPlaybackStopped(stopInfo)
//            let _ = try await userSession.client.send(request)
//        }
//    }
//
//    func sendPauseReport() {
//
//        #if DEBUG
//        guard Defaults[.sendProgressReports] else { return }
//        #endif
//
//        logger.debug("sent pause report")
//
//        currentProgressWorkItem?.cancel()
//
//        Task {
//            let startInfo = PlaybackStartInfo(
//                audioStreamIndex: audioTrackIndex,
//                isPaused: true,
//                itemID: currentViewModel.item.id,
//                mediaSourceID: currentViewModel.mediaSource.id,
//                positionTicks: currentProgressHandler.seconds * 10_000_000,
//                sessionID: currentViewModel.playSessionID,
//                subtitleStreamIndex: subtitleTrackIndex
//            )
//
//            let request = Paths.reportPlaybackStart(startInfo)
//            let _ = try await userSession.client.send(request)
//        }
//    }
//
//    func sendProgressReport() {
//
//        #if DEBUG
//        guard Defaults[.sendProgressReports] else { return }
//        #endif
//
//        let progressTask = DispatchWorkItem {
//            self.sendProgressReport()
//        }
//
//        currentProgressWorkItem = progressTask
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: progressTask)
//
//        Task {
//            let progressInfo = PlaybackProgressInfo(
//                audioStreamIndex: audioTrackIndex,
//                isPaused: false,
//                itemID: currentViewModel.item.id,
//                mediaSourceID: currentViewModel.item.id,
//                playSessionID: currentViewModel.playSessionID,
//                positionTicks: currentProgressHandler.seconds * 10_000_000,
//                sessionID: currentViewModel.playSessionID,
//                subtitleStreamIndex: subtitleTrackIndex
//            )
//
//            let request = Paths.reportPlaybackProgress(progressInfo)
//            let _ = try await userSession.client.send(request)
//
//            logger.debug("sent progress task")
//        }
//    }

    // MARK: commands

//    private func handleCommand(command: NowPlayableCommand, event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
//        switch command {
//        case .togglePausePlay:
//            if state == .playing {
//                proxy.pause()
//            } else {
//                proxy.play()
//            }
//        case .play:
//            proxy.play()
//        case .pause:
//            proxy.pause()
//        case .skipForward:
//            proxy.jumpForward(15)
//        case .skipBackward:
//            proxy.jumpBackward(15)
//        case .changePlaybackPosition:
//            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
//            proxy.setTime(event.positionTime)
    ////        case .nextTrack:
    ////            selectNextViewModel()
    ////        case .previousTrack:
    ////            selectPreviousViewModel()
//        default: ()
//        }
//
//        return .success
//    }
}
