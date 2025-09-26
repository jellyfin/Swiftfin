//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Logging
import MediaPlayer
import Nuke

// TODO: ensure proper state handling
//       - manager states
//       - playback request states
// TODO: have MediaPlayerItem report supported commands

@MainActor
class NowPlayableObserver: ViewModel, MediaPlayerObserver {

    private var defaultRegisteredCommands: [NowPlayableCommand] {
        [
            .play,
            .pause,
            .togglePausePlay,
            .skipBackward,
            .skipForward,
            .changePlaybackPosition,
            // TODO: only register next/previous if there is a queue
//            .nextTrack,
//            .previousTrack,
        ]
    }

    private var itemImageCancellable: AnyCancellable?
    private var playbackRequestStateBeforeInterruption: MediaPlayerManager.PlaybackRequestStatus = .playing

    weak var manager: MediaPlayerManager? {
        willSet {
            guard let newValue else { return }
            setup(with: newValue)
        }
    }

    private func setup(with manager: MediaPlayerManager) {
        do {
            try startSession()
        } catch {
            logger.critical("Unable to activate audio session: \(error.localizedDescription)")
        }

        cancellables = []

        manager.actions
            .sink { [weak self] newValue in self?.actionDidChange(newValue) }
            .store(in: &cancellables)

        manager.$playbackItem
            .sink { [weak self] newValue in self?.playbackItemDidChange(newValue) }
            .store(in: &cancellables)

        manager.$playbackRequestStatus
            .sink { [weak self] newValue in self?.playbackRequestStatusDidChange(newValue) }
            .store(in: &cancellables)

        manager.secondsBox.$value
            .sink { [weak self] newValue in self?.secondsDidChange(newValue) }
            .store(in: &cancellables)

        Notifications[.avAudioSessionInterruption]
            .publisher
            .sink { i in
                Task { @MainActor in
                    self.handleInterruption(type: i.0, options: i.1)
                }
            }
            .store(in: &cancellables)

        Task { @MainActor in
            configureRemoteCommands(
                defaultRegisteredCommands,
                commandHandler: handleCommand
            )
        }
    }

    private func playbackRequestStatusDidChange(_ newStatus: MediaPlayerManager.PlaybackRequestStatus) {
        handleNowPlayablePlaybackChange(
            playing: newStatus == .playing,
            metadata: .init(
                position: manager?.seconds ?? .zero,
                duration: manager?.item.runtime ?? .zero
            )
        )
    }

    private func secondsDidChange(_ newSeconds: Duration) {
        handleNowPlayablePlaybackChange(
            playing: true,
            metadata: .init(
                position: newSeconds,
                duration: manager?.item.runtime ?? .zero
            )
        )
    }

    private func actionDidChange(_ newAction: MediaPlayerManager._Action) {
        switch newAction {
        case .stop, .error:
            handleStopAction()
        default: ()
        }
    }

    // TODO: remove and respond to manager action publisher instead
    // TODO: register different commands based on item capabilities
    private func playbackItemDidChange(_ newItem: MediaPlayerItem?) {
        itemImageCancellable?.cancel()
        itemImageCancellable = nil
        guard let newItem else { return }

        setNowPlayingMetadata(newItem.baseItem.nowPlayableStaticMetadata())

        itemImageCancellable = Task {
            let currentBaseItem = newItem.baseItem
            guard let image = await newItem.thumbnailProvider?() else { return }
            guard manager?.item.id == currentBaseItem.id else { return }

            await MainActor.run {
                setNowPlayingMetadata(
                    currentBaseItem.nowPlayableStaticMetadata(image)
                )
            }
        }
        .asAnyCancellable()

        handleNowPlayablePlaybackChange(
            playing: true,
            metadata: .init(
                position: manager?.seconds ?? .zero,
                duration: manager?.item.runtime ?? .zero
            )
        )
    }

    private func handleStopAction() {
        cancellables = []

        for command in defaultRegisteredCommands {
            command.removeHandler()
        }

        Task(priority: .userInitiated) {
            // TODO: figure out way to not need delay
            // Delay to wait for io to stop
            try? await Task.sleep(for: .seconds(0.3))

            do {
                try stopSession()
            } catch {
                logger.critical("Unable to stop audio session: \(error.localizedDescription)")
            }
        }
    }

    // TODO: complete by referencing apple code
    //       - restart
    @MainActor
    private func handleInterruption(
        type: AVAudioSession.InterruptionType,
        options: AVAudioSession.InterruptionOptions
    ) {
        switch type {
        case .began:
            playbackRequestStateBeforeInterruption = manager?.playbackRequestStatus ?? .playing
            manager?.setPlaybackRequestStatus(status: .paused)
        case .ended:
            do {
                try startSession()

                if playbackRequestStateBeforeInterruption == .playing {
                    if options.contains(.shouldResume) {
                        manager?.setPlaybackRequestStatus(status: .playing)
                    } else {
                        manager?.setPlaybackRequestStatus(status: .paused)
                    }
                }
            } catch {
                logger.critical("Unable to reactivate audio session after interruption: \(error.localizedDescription)")
                manager?.stop()
            }
        @unknown default: ()
        }
    }

    @MainActor
    private func handleCommand(
        command: NowPlayableCommand,
        event: MPRemoteCommandEvent
    ) -> MPRemoteCommandHandlerStatus {
        switch command {
        case .pause:
            manager?.setPlaybackRequestStatus(status: .paused)
        case .play:
            manager?.setPlaybackRequestStatus(status: .playing)
        case .togglePausePlay:
            manager?.togglePlayPause()
        case .skipBackward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            manager?.proxy?.jumpBackward(.seconds(event.interval))
        case .skipForward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            manager?.proxy?.jumpForward(.seconds(event.interval))
        case .changePlaybackPosition:
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            manager?.proxy?.setSeconds(Duration.seconds(event.positionTime))
        case .nextTrack:
            guard let nextItem = manager?.queue?.nextItem else { return .commandFailed }
            manager?.playNewItem(provider: nextItem)
        case .previousTrack:
            guard let previousItem = manager?.queue?.previousItem else { return .commandFailed }
            manager?.playNewItem(provider: previousItem)
        default: ()
        }

        return .success
    }

    private func handleNowPlayablePlaybackChange(
        playing: Bool,
        metadata: NowPlayableDynamicMetadata
    ) {
        setNowPlayingPlaybackInfo(metadata)
        MPNowPlayingInfoCenter.default().playbackState = playing ? .playing : .paused
    }

    private func configureRemoteCommands(
        _ commands: [NowPlayableCommand],
        commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    ) {
        guard commands.isNotEmpty else { return }

        for command in commands {
            command.addHandler(commandHandler)
            command.isEnabled(true)
        }
    }

    private func setNowPlayingMetadata(_ metadata: NowPlayableStaticMetadata) {

        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo: [String: Any] = [:]

        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = metadata.mediaType.rawValue
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = metadata.isLiveStream
        nowPlayingInfo[MPMediaItemPropertyTitle] = metadata.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = metadata.artist
        nowPlayingInfo[MPMediaItemPropertyArtwork] = metadata.artwork
        nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = metadata.albumArtist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = metadata.albumTitle

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    private func setNowPlayingPlaybackInfo(_ metadata: NowPlayableDynamicMetadata) {

        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo: [String: Any] = nowPlayingInfoCenter.nowPlayingInfo ?? [:]

        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Float(metadata.duration.seconds)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Float(metadata.position.seconds)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = metadata.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyCurrentLanguageOptions] = metadata.currentLanguageOptions
        nowPlayingInfo[MPNowPlayingInfoPropertyAvailableLanguageOptions] = metadata.availableLanguageOptionGroups

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    private func startSession() throws {

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            logger.trace("Started AVAudioSession")
        } catch {
            logger.critical("Unable to activate AVAudioSession instance: \(error.localizedDescription)")
            throw error
        }
    }

    private func stopSession() throws {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            logger.trace("Stopped AVAudioSession")
        } catch {
            logger.critical("Unable to deactivate AVAudioSession instance: \(error.localizedDescription)")
            throw error
        }
    }
}
