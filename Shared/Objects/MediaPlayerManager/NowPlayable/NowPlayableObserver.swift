//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import Logging
import MediaPlayer
import UIKit

@MainActor
final class NowPlayableObserver: MediaSessionObserver {

    private var isActive = false
    private let logger = Logger.swiftfin()
    private weak var mediaSession: MediaSession?
    private weak var observedItem: MediaPlayerItem?
    private var ownsAudioSession = false
    private var playbackRequestStateBeforeInterruption: MediaSession.PlaybackRequestStatus?

    private var cancellables = Set<AnyCancellable>()
    private var commandTargets: [NowPlayableCommand: Any] = [:]
    private var itemImageCancellable: AnyCancellable?
    private var programRefreshTask: AnyCancellable?
    private var programEndDate: Date?
    private var itemMetadata: NowPlayableStaticMetadata?
    private var itemArtwork: UIImage?
    private var artworkSources: [ImageSource]?
    private var languageOptions = NowPlayableLanguageOptions()
    private var publishedPositionSecond: Int64?

    private var registeredCommands: [NowPlayableCommand] {
        [
            .play,
            .pause,
            .stop,
            .togglePausePlay,
            .skipBackward,
            .skipForward,
            .changePlaybackPosition,
            .nextTrack,
            .previousTrack,
            .changePlaybackRate,
            .enableLanguageOption,
            .disableLanguageOption,
        ]
    }

    private var supportedRates: [Double] {
        Set(Defaults[.VideoPlayer.Playback.rates] + [mediaSession?.effectiveRate ?? 1])
            .filter { $0.isFinite && (mediaSession?.player?.supportedRates ?? 0.1 ... 5).contains($0) }
            .sorted()
    }

    func observe(_ mediaSession: MediaSession) -> AnyCancellable {
        self.mediaSession = mediaSession
        setup()

        return AnyCancellable { [self] in
            MainActor.assumeIsolated {
                stop()
                self.mediaSession = nil
            }
        }
    }

    private func setup() {
        isActive = true

        for command in NowPlayableCommand.allCases {
            command.isEnabled(false)
        }

        for command in registeredCommands {
            commandTargets[command] = command.addHandler { [weak self] action in
                self?.handle(action) ?? .commandFailed
            }
        }

        playbackItemDidChange(mediaSession?.playbackItem)

        Task { [weak self, weak mediaSession] in
            let items = ObservableValues { [weak mediaSession] in
                mediaSession?.playbackItem
            }

            for await item in items {
                guard !Task.isCancelled else { return }
                guard item === mediaSession?.playbackItem else { continue }

                self?.playbackItemDidChange(item)
            }
        }
        .store(in: &cancellables)

        Task { [weak self, weak mediaSession] in
            let metadata = ObservableValues { [weak mediaSession] in
                mediaSession?.playbackItem?.baseItem
            }

            for await _ in metadata {
                guard !Task.isCancelled else { return }

                self?.playbackItemDidChange(mediaSession?.playbackItem)
                self?.metadataDidChange()
            }
        }
        .store(in: &cancellables)

        Task { [weak self, weak mediaSession] in
            let playback = ObservableValues { [weak mediaSession] in
                (
                    mediaSession?.state,
                    mediaSession?.playbackRequestStatus,
                    mediaSession?.playbackState,
                    mediaSession?.isSeeking,
                    mediaSession?.rate
                )
            }

            for await _ in playback {
                guard !Task.isCancelled else { return }

                self?.updatePlaybackInfo()
                self?.updateRemoteCommands()
            }
        }
        .store(in: &cancellables)

        Task { [weak self, weak mediaSession] in
            let languages = ObservableValues { [weak mediaSession] in
                (
                    mediaSession?.playbackItem?.effectiveSubtitleStreamIndex,
                    mediaSession?.playbackItem?.effectiveSecondarySubtitleStreamIndex,
                    mediaSession?.playbackItem?.selectedAudioStreamIndex
                )
            }

            for await _ in languages {
                guard !Task.isCancelled else { return }

                self?.updateLanguageOptions()
            }
        }
        .store(in: &cancellables)

        Task { [weak self, weak mediaSession] in
            let adjacentItems = ObservableValues { [weak mediaSession] in
                (mediaSession?.queue?.nextItem, mediaSession?.queue?.previousItem)
            }

            for await _ in adjacentItems {
                guard !Task.isCancelled else { return }

                self?.updateRemoteCommands()
            }
        }
        .store(in: &cancellables)

        Task { [weak self, weak mediaSession] in
            let seconds = ObservableValues { [weak mediaSession] in
                mediaSession?.observedSeconds.components.seconds
            }

            for await second in seconds {
                guard !Task.isCancelled, let self else { return }
                guard second != publishedPositionSecond else { continue }

                // Now Playing extrapolates between positions using the published rate.
                // State, rate, and seek changes still publish immediately above.
                updatePlaybackInfo()
            }
        }
        .store(in: &cancellables)

        Defaults.publisher(.VideoPlayer.Playback.rates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateRemoteCommands() }
            .store(in: &cancellables)

        Notifications[.avAudioSessionInterruption]
            .publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] interruption in
                self?.handleInterruption(type: interruption.0, options: interruption.1)
            }
            .store(in: &cancellables)

        Notifications[.avAudioSessionRouteChange]
            .publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reason in
                guard self?.ownsAudioSession == true,
                      reason == .oldDeviceUnavailable,
                      self?.mediaSession?.outputPolicy.isChangingRoute != true else { return }

                self?.playbackRequestStateBeforeInterruption = .paused
                self?.mediaSession?.setPlaybackRequestStatus(status: .paused)
            }
            .store(in: &cancellables)

        updateRemoteCommands()
    }

    private func playbackItemDidChange(_ item: MediaPlayerItem?) {
        guard observedItem !== item else { return }

        observedItem = item
        publishedPositionSecond = nil
        itemImageCancellable = nil
        programRefreshTask = nil
        programEndDate = nil

        itemMetadata = nil
        itemArtwork = nil
        artworkSources = nil
        languageOptions = NowPlayableLanguageOptions(item: item)

        guard item != nil else {
            updatePlaybackInfo()
            updateRemoteCommands()
            return
        }

        configureAudioSession()
        metadataDidChange()
        updateRemoteCommands()
    }

    private func metadataDidChange() {
        guard isActive, let item = mediaSession?.playbackItem, observedItem === item else { return }

        let baseItem = item.baseItem
        let metadata = baseItem.nowPlayableStaticMetadata()

        if itemMetadata != metadata {
            let previousType = itemMetadata?.mediaType
            itemMetadata = metadata

            if let previousType, previousType != metadata.mediaType {
                configureAudioSession()
            }

            publishMetadata()
        }

        let sources = baseItem.nowPlayingImageSources

        if artworkSources != sources {
            itemImageCancellable = nil
            artworkSources = sources
            itemArtwork = nil
            publishMetadata()

            itemImageCancellable = Task { [weak self, weak item] in
                guard let item else { return }

                let image = await item.thumbnailProvider?()
                guard !Task.isCancelled,
                      let self,
                      isActive,
                      mediaSession?.playbackItem === item,
                      item.baseItem.nowPlayingImageSources == sources else { return }

                itemArtwork = image

                // Read the current metadata after awaiting to avoid replacing an edit with an old snapshot.
                itemMetadata = item.baseItem.nowPlayableStaticMetadata()
                publishMetadata()
            }
            .asAnyCancellable()
        }

        scheduleProgramRefresh()
        updatePlaybackInfo()
    }

    private func publishMetadata() {
        guard isActive, let item = mediaSession?.playbackItem, observedItem === item else { return }

        let center = MPNowPlayingInfoCenter.default()
        var info = center.nowPlayingInfo ?? [:]
        item.baseItem.nowPlayableStaticMetadata(itemArtwork).update(&info)
        center.nowPlayingInfo = info

        (mediaSession?.player as? MediaPlayerMetadataProviding)?.updateMetadata(for: item, artwork: itemArtwork)
        updatePlaybackInfo()
    }

    private func scheduleProgramRefresh() {
        guard let mediaSession, let item = mediaSession.playbackItem, item.baseItem.isLiveStream else { return }

        let session = mediaSession.userSession

        let endDate = item.baseItem.currentProgram?.endDate
        guard programRefreshTask == nil || programEndDate != endDate else { return }

        programRefreshTask = nil
        programEndDate = endDate

        programRefreshTask = Task { [weak self, weak item] in
            var hasRefreshed = false

            while !Task.isCancelled {
                guard let item else { return }

                let endDate = item.baseItem.currentProgram?.endDate
                let minimumDelay: TimeInterval = hasRefreshed ? 30 : 1
                let delay = endDate.map { max($0.timeIntervalSinceNow + 1, minimumDelay) } ?? 30

                do {
                    try await Task.sleep(for: .seconds(delay))
                } catch {
                    return
                }

                guard let self, isActive, self.mediaSession?.playbackItem === item else { return }

                do {
                    _ = try await session.getFullItem(item.baseItem)
                } catch {
                    guard !Task.isCancelled else { return }

                    logger.debug("Unable to refresh current program: \(error.localizedDescription)")
                }

                hasRefreshed = true
            }
        }
        .asAnyCancellable()
    }

    private func updateLanguageOptions() {
        languageOptions = NowPlayableLanguageOptions(item: mediaSession?.playbackItem)
        updatePlaybackInfo()
        updateRemoteCommands()
    }

    private func updatePlaybackInfo() {
        guard isActive, let mediaSession else { return }

        let center = MPNowPlayingInfoCenter.default()
        guard let item = mediaSession.playbackItem else {
            // Keep the last item's metadata while resolution resets the session timeline.
            guard var info = center.nowPlayingInfo else { return }

            info[MPNowPlayingInfoPropertyPlaybackRate] = 0
            info[MPNowPlayingInfoPropertyCurrentLanguageOptions] = []
            info[MPNowPlayingInfoPropertyAvailableLanguageOptions] = []
            center.nowPlayingInfo = info

            return
        }

        publishedPositionSecond = mediaSession.observedSeconds.components.seconds

        let state = mediaSession.playbackState
        let isAdvancing = mediaSession.playbackRequestStatus == .playing && state.isPlaying
            && !mediaSession.isSeeking && !state.isSeeking && !state.isBuffering && !state.isWaitingForDisplay

        let metadata = NowPlayableDynamicMetadata(
            rate: isAdvancing ? mediaSession.effectiveRate : 0,
            defaultRate: mediaSession.effectiveRate,
            position: mediaSession.observedSeconds,
            duration: item.baseItem.isLiveStream ? nil : item.baseItem.runtime ?? state.duration,
            currentLanguageOptions: languageOptions.current,
            availableLanguageOptionGroups: languageOptions.groups
        )

        var info = center.nowPlayingInfo ?? [:]
        metadata.update(&info)
        center.nowPlayingInfo = info
    }

    private func updateRemoteCommands() {
        let canControl = mediaSession?.canControlPlayback == true

        for command in [NowPlayableCommand.play, .pause, .stop, .togglePausePlay] {
            command.isEnabled(canControl)
        }

        for command in [NowPlayableCommand.skipBackward, .skipForward, .changePlaybackPosition] {
            command.isEnabled(mediaSession?.canSeek == true)
        }

        NowPlayableCommand.nextTrack.isEnabled(canControl && mediaSession?.queue?.hasNextItem == true)
        NowPlayableCommand.previousTrack.isEnabled(canControl && mediaSession?.queue?.hasPreviousItem == true)

        NowPlayableCommand.changePlaybackRate.isEnabled(canControl && mediaSession?.item.isLiveStream == false)
        MPRemoteCommandCenter.shared().changePlaybackRateCommand.supportedPlaybackRates = supportedRates.map { NSNumber(value: $0) }

        let canSelectLanguage = mediaSession?.playbackItem?.canSelectTracks == true && languageOptions.groups.isNotEmpty
        NowPlayableCommand.enableLanguageOption.isEnabled(canSelectLanguage)
        NowPlayableCommand.disableLanguageOption
            .isEnabled(canSelectLanguage && languageOptions.current.contains { $0.languageOptionType == .legible })
    }

    /// Decode framework events at registration and keep transport decisions on the main actor.
    func handle(_ action: NowPlayableCommand.Action) -> MPRemoteCommandHandlerStatus {
        guard isActive, let mediaSession, mediaSession.canControlPlayback else { return .commandFailed }

        switch action {
        case .pause:
            if playbackRequestStateBeforeInterruption != nil {
                playbackRequestStateBeforeInterruption = .paused
            }

            mediaSession.setPlaybackRequestStatus(status: .paused)

        case .play:
            do {
                try startSession()
            } catch {
                return .commandFailed
            }

            playbackRequestStateBeforeInterruption = nil
            mediaSession.setPlaybackRequestStatus(status: .playing)

        case .togglePausePlay:
            return handle(mediaSession.playbackRequestStatus == .playing ? .pause : .play)

        case .stop:
            mediaSession.stop()

        case .nextTrack, .previousTrack:
            let intent: PlaybackIntent? = if case .nextTrack = action {
                mediaSession.queue?.nextItem
            } else {
                mediaSession.queue?.previousItem
            }

            guard let intent, mediaSession.playNewItem(intent: intent) != nil else { return .noSuchContent }

        case let .skip(offset):
            guard mediaSession.seek(by: offset) else { return .commandFailed }

        case let .seek(position):
            guard mediaSession.seek(to: position) else { return .commandFailed }

        case let .rate(rate):
            guard rate.isFinite,
                  rate > 0,
                  !mediaSession.item.isLiveStream,
                  let supported = supportedRates.first(where: { abs($0 - rate) < 0.0001 }) else { return .commandFailed }

            mediaSession.rate = supported

        case let .language(option, enabled):
            guard let item = mediaSession.playbackItem,
                  NowPlayableLanguageOptions(item: item).select(option, enabled: enabled, on: item) else { return .commandFailed }

            updateLanguageOptions()
        }

        updatePlaybackInfo()
        updateRemoteCommands()

        return .success
    }

    func stop() {
        guard isActive else { return }

        isActive = false
        cancellables.removeAll()
        itemImageCancellable = nil
        programRefreshTask = nil

        for (command, target) in commandTargets {
            command.remoteCommand.removeTarget(target)
            command.isEnabled(false)
        }

        commandTargets.removeAll()

        itemMetadata = nil
        itemArtwork = nil
        artworkSources = nil
        observedItem = nil
        publishedPositionSecond = nil
        playbackRequestStateBeforeInterruption = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        do {
            if ownsAudioSession {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                ownsAudioSession = false
            }
        } catch {
            logger.warning("Unable to stop audio session: \(error.localizedDescription)")
        }
    }

    private func handleInterruption(type: AVAudioSession.InterruptionType, options: AVAudioSession.InterruptionOptions) {
        guard ownsAudioSession else { return }

        switch type {
        case .began:
            playbackRequestStateBeforeInterruption = mediaSession?.playbackRequestStatus ?? .paused
            mediaSession?.setPlaybackRequestStatus(status: .paused)

        case .ended:
            let previous = playbackRequestStateBeforeInterruption
            playbackRequestStateBeforeInterruption = nil

            guard previous == .playing, options.contains(.shouldResume) else { return }

            do {
                try startSession()
                mediaSession?.setPlaybackRequestStatus(status: .playing)
            } catch {
                logger.error("Unable to reactivate audio session: \(error.localizedDescription)")
            }

        @unknown default:
            break
        }
    }

    private func configureAudioSession() {
        do {
            try startSession()
        } catch {
            logger.warning("Unable to update audio session: \(error.localizedDescription)")
        }
    }

    private func startSession() throws {
        guard mediaSession?.isRemotePlayback != true else { return }

        let session = AVAudioSession.sharedInstance()
        let isAudio = mediaSession?.item.nowPlayableStaticMetadata().mediaType == .audio
        let policy = mediaSession?.outputPolicy.routeSharingPolicy ?? .default

        try session.setCategory(.playback, mode: isAudio ? .default : .moviePlayback, policy: policy)
        try session.setSupportsMultichannelContent(true)
        try session.setActive(true)

        ownsAudioSession = true
    }
}
