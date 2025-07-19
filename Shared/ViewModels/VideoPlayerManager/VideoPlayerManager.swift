//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Combine
import Defaults
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

// TODO: transition to `Stateful`
class VideoPlayerManager: ViewModel {

    class CurrentProgressHandler: ObservableObject {

        @Published
        var progress: CGFloat = 0
        @Published
        var scrubbedProgress: CGFloat = 0

        @Published
        var seconds: Int = 0
        @Published
        var scrubbedSeconds: Int = 0
    }

    @Published
    var audioTrackIndex: Int = -1
    @Published
    var state: VLCVideoPlayer.State = .opening
    @Published
    var subtitleTrackIndex: Int = -1
    @Published
    var playbackSpeed: PlaybackSpeed = PlaybackSpeed.one

    // MARK: ViewModel

    @Published
    var previousViewModel: VideoPlayerViewModel?
    @Published
    var currentViewModel: VideoPlayerViewModel! {
        willSet {
            guard let newValue else { return }
            hasSentStart = false
            getAdjacentEpisodes(for: newValue.item)
        }
        didSet {
            updateNowPlayingInfo()
        }
    }

    @Published
    var nextViewModel: VideoPlayerViewModel? {
        didSet {
            commandCenter.nextTrackCommand.isEnabled = nextViewModel != nil
        }
    }

    var currentProgressHandler: CurrentProgressHandler = .init()
    let proxy: VLCVideoPlayer.Proxy = .init()

    private var currentProgressWorkItem: DispatchWorkItem?
    private var hasSentStart = false

    private let commandCenter = MPRemoteCommandCenter.shared()

    override init() {
        super.init()

        setupControlListeners()
        setupNotifications()

        // Enable remote control events
        UIApplication.shared.beginReceivingRemoteControlEvents()
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

        if subtitleTrackIndex != playbackInformation.currentSubtitleTrack.index {
            subtitleTrackIndex = playbackInformation.currentSubtitleTrack.index
        }

        // Update now playing info with current playback time
        updateNowPlayingPlaybackInfo()
    }

    func onStateUpdated(newState: VLCVideoPlayer.State) {
        guard state != newState else { return }
        state = newState

        if !hasSentStart, newState == .playing {
            hasSentStart = true
            sendStartReport()
        }

        if hasSentStart, newState == .paused {
            hasSentStart = false
            sendPauseReport()
        }

        if newState == .stopped || newState == .ended {
            sendStopReport()
        }

        // Update now playing playback rate when state changes
        updateNowPlayingPlaybackInfo()
    }

    func getAdjacentEpisodes(for item: BaseItemDto) {
        Task { @MainActor in
            guard let seriesID = item.seriesID, item.type == .episode else { return }

            let parameters = Paths.GetEpisodesParameters(
                userID: userSession.user.id,
                fields: .MinimumFields,
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
                self.commandCenter.previousTrackCommand.isEnabled = previousViewModel != nil
            }
        }
    }

    func sendStartReport() {

        #if DEBUG
        guard Defaults[.sendProgressReports] else { return }
        #endif

        currentProgressWorkItem?.cancel()

        logger.debug("sent start report")

        Task {
            let startInfo = PlaybackStartInfo(
                audioStreamIndex: audioTrackIndex,
                itemID: currentViewModel.item.id,
                mediaSourceID: currentViewModel.mediaSource.id,
                playbackStartTimeTicks: Int(Date().timeIntervalSince1970) * 10_000_000,
                positionTicks: currentProgressHandler.seconds * 10_000_000,
                sessionID: currentViewModel.playSessionID,
                subtitleStreamIndex: subtitleTrackIndex
            )

            let request = Paths.reportPlaybackStart(startInfo)
            let _ = try await userSession.client.send(request)

            let progressTask = DispatchWorkItem {
                self.sendProgressReport()
            }

            currentProgressWorkItem = progressTask

            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: progressTask)
        }
    }

    func sendStopReport() {

        #if DEBUG
        guard Defaults[.sendProgressReports] else { return }
        #endif

        logger.debug("sent stop report")

        currentProgressWorkItem?.cancel()

        Task {
            let stopInfo = PlaybackStopInfo(
                itemID: currentViewModel.item.id,
                mediaSourceID: currentViewModel.mediaSource.id,
                positionTicks: currentProgressHandler.seconds * 10_000_000,
                sessionID: currentViewModel.playSessionID
            )

            let request = Paths.reportPlaybackStopped(stopInfo)
            let _ = try await userSession.client.send(request)

            // TODO: Revise as part of the PlayerManager Rework
            if let itemID = currentViewModel.item.id {
                Notifications[.itemShouldRefreshMetadata].post(itemID)
            }

            // TODO: Revise as part of the PlayerManager Rework
            if let seriesID = currentViewModel.item.seriesID {
                Notifications[.itemShouldRefreshMetadata].post(seriesID)
            }
        }
    }

    func sendPauseReport() {

        #if DEBUG
        guard Defaults[.sendProgressReports] else { return }
        #endif

        logger.debug("sent pause report")

        currentProgressWorkItem?.cancel()

        Task {
            let startInfo = PlaybackStartInfo(
                audioStreamIndex: audioTrackIndex,
                isPaused: true,
                itemID: currentViewModel.item.id,
                mediaSourceID: currentViewModel.mediaSource.id,
                positionTicks: currentProgressHandler.seconds * 10_000_000,
                sessionID: currentViewModel.playSessionID,
                subtitleStreamIndex: subtitleTrackIndex
            )

            let request = Paths.reportPlaybackStart(startInfo)
            let _ = try await userSession.client.send(request)
        }
    }

    func sendProgressReport() {

        #if DEBUG
        guard Defaults[.sendProgressReports] else { return }
        #endif

        let progressTask = DispatchWorkItem {
            self.sendProgressReport()
        }

        currentProgressWorkItem = progressTask

        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: progressTask)

        Task {
            let progressInfo = PlaybackProgressInfo(
                audioStreamIndex: audioTrackIndex,
                isPaused: false,
                itemID: currentViewModel.item.id,
                mediaSourceID: currentViewModel.item.id,
                playSessionID: currentViewModel.playSessionID,
                positionTicks: currentProgressHandler.seconds * 10_000_000,
                sessionID: currentViewModel.playSessionID,
                subtitleStreamIndex: subtitleTrackIndex
            )

            let request = Paths.reportPlaybackProgress(progressInfo)
            let _ = try await userSession.client.send(request)

            logger.debug("sent progress task")
        }
    }

    func setupControlListeners() {
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.proxy.pause()
            return .success
        }

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.proxy.play()
            return .success
        }

        // Skip forward/backward commands
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 15)]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let self = self,
                  let skipEvent = event as? MPSkipIntervalCommandEvent else { return .commandFailed }

            let currentTime = self.currentProgressHandler.seconds
            let newTime = currentTime + Int(skipEvent.interval)
            self.proxy.setTime(.seconds(newTime))

            return .success
        }

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let self = self,
                  let skipEvent = event as? MPSkipIntervalCommandEvent else { return .commandFailed }

            let currentTime = self.currentProgressHandler.seconds
            let newTime = max(0, currentTime - Int(skipEvent.interval))
            self.proxy.setTime(.seconds(newTime))

            return .success
        }

        // Change playback position command (scrubbing)
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }

            self.proxy.setTime(.seconds(Int(positionEvent.positionTime)))

            return .success
        }

        // Previous/Next track commands for episodes
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            if self.previousViewModel != nil {
                self.selectPreviousViewModel()
                return .success
            }

            return .noActionableNowPlayingItem
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            if self.nextViewModel != nil {
                self.selectNextViewModel()
                return .success
            }

            return .noActionableNowPlayingItem
        }
    }

    func setupNotifications() {
        Notifications[.interruption].subscribe(
            self,
            selector: #selector(onInterrupt(_:)),
            observed: AVAudioSession.sharedInstance()
        )
    }

    @objc
    func onInterrupt(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else {
            return
        }

        switch type {
        case .began:
            self.proxy.pause()
        case .ended:
            if let rawOption = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: rawOption).contains(.shouldResume)
            {
                self.proxy.play()
            }
        @unknown default:
            break
        }
    }

    // MARK: - Now Playing Info Center

    func updateNowPlayingInfo() {
        guard let currentViewModel else { return }

        let nowPlayingInfo = NSMutableDictionary()

        // Basic metadata
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentViewModel.item.displayTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentViewModel.item.seriesName ?? currentViewModel.item.albumArtist ?? ""
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = currentViewModel.item.album ?? currentViewModel.item.seriesName ?? ""

        // Duration
        if let runTimeTicks = currentViewModel.item.runTimeTicks {
            let durationInSeconds = Double(runTimeTicks) / 10_000_000.0
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = durationInSeconds
        }

        // Episode information - use track number as episode number for TV shows
        if currentViewModel.item.type == .episode {
            if let episodeNumber = currentViewModel.item.indexNumber {
                nowPlayingInfo[MPMediaItemPropertyAlbumTrackNumber] = episodeNumber
            }
            // Season information can be included in the album title
            if let seasonNumber = currentViewModel.item.parentIndexNumber {
                let seasonText = "Season \(seasonNumber)"
                if let seriesName = currentViewModel.item.seriesName {
                    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "\(seriesName) - \(seasonText)"
                } else {
                    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = seasonText
                }
            }
        }

        // Set initial playback info
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(currentProgressHandler.seconds)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = state == .playing ? 1.0 : 0.0

        // Set initial info without artwork
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo as? [String: Any]

        // Load artwork asynchronously
        Task {
            await loadAndSetArtwork(for: currentViewModel.item)
        }
    }

    func updateNowPlayingPlaybackInfo() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(currentProgressHandler.seconds)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = state == .playing ? Double(playbackSpeed.rawValue) : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func loadAndSetArtwork(for item: BaseItemDto) async {
        do {
            // Use the existing BaseItemDto extension to get the primary image URL
            guard let baseImageURL = item.imageURL(.primary, maxWidth: 600) else { return }

            // Add API key to URL for authentication
            guard var components = URLComponents(url: baseImageURL, resolvingAgainstBaseURL: false) else { return }

            let apiKey = userSession.user.accessToken
            components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "api_key", value: apiKey)]

            guard let imageURL = components.url else { return }

            // Download the image
            let (data, _) = try await URLSession.shared.data(from: imageURL)

            guard let image = UIImage(data: data) else { return }

            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }

            await MainActor.run {
                guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        } catch {
            logger.error("Failed to load artwork for Now Playing: \(error)")
        }
    }
}
