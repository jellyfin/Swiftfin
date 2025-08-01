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

class NowPlayableListener: MediaPlayerListener {

    private let logger = Logger.swiftfin()

    private var cancellables: Set<AnyCancellable> = []
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

    weak var manager: MediaPlayerManager? {
        willSet {
            guard let newValue else { return }
            setup(with: newValue)
        }
    }

    init(manager: MediaPlayerManager) {
        self.manager = manager

        configureRemoteCommands(
            defaultRegisteredCommands,
            commandHandler: handleCommand
        )
    }

    private func setup(with manager: MediaPlayerManager) {
        manager.$playbackItem.sink(receiveValue: itemDidChange).store(in: &cancellables)
        manager.secondsBox.$value.sink(receiveValue: secondsDidChange).store(in: &cancellables)
        manager.$state.sink(receiveValue: stateDidChange).store(in: &cancellables)
        manager.events.sink(receiveValue: didReceiveManagerEvent).store(in: &cancellables)
    }

    private func itemDidChange(newItem: MediaPlayerItem?) {
        guard let newItem else { return }

        handleNowPlayableItemChange(metadata: .init(mediaType: .video, title: newItem.baseItem.displayTitle))

        itemImageCancellable = Task {
            guard let image = await newItem.thumbnailProvider?() else { return }

            await MainActor.run {
                setNowPlayingMetadata(
                    .init(
                        mediaType: .video,
                        title: newItem.baseItem.displayTitle,
                        artwork: MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    )
                )
            }
        }
        .asAnyCancellable()
    }

    private func secondsDidChange(newSeconds: Duration) {
        handleNowPlayablePlaybackChange(
            playing: true,
            metadata: .init(
                position: newSeconds,
                duration: manager?.item.runtime ?? .zero
            )
        )
    }

    private func stateDidChange(newState: MediaPlayerManager.State) {
        handleNowPlayablePlaybackChange(
            playing: true,
            metadata: .init(
                position: manager?.seconds ?? .zero,
                duration: manager?.item.runtime ?? .zero
            )
        )
    }

    private func didReceiveManagerEvent(event: MediaPlayerManager.Event) {
        switch event {
        case .playbackStopped:
            cancellables = []

            for command in defaultRegisteredCommands {
                command.removeHandler()
            }
        default: ()
        }
    }

    private func handleCommand(command: NowPlayableCommand, event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        switch command {
        case .pause:
            manager?.proxy?.pause()
        case .play:
            manager?.proxy?.play()
        case .togglePausePlay:
            if manager?.playbackRequestStatus == .playing {
                manager?.proxy?.pause()
            } else {
                manager?.proxy?.play()
            }
        case .skipBackward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            manager?.proxy?.jumpBackward(.seconds(event.interval))
        case .skipForward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            manager?.proxy?.jumpForward(.seconds(event.interval))
        case .changePlaybackPosition:
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            manager?.proxy?.setSeconds(Duration.seconds(event.positionTime))
        case .nextTrack: ()
        case .previousTrack: ()
        default: ()
        }

        return .success
    }

    func startSession() {

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            logger.critical("Unable to activate AVAudioSession instance: \(error.localizedDescription)")
        }
    }

    func stopSession() {

        for command in NowPlayableCommand.allCases {
            command.removeHandler()
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            logger.critical("Unable to deactivate AVAudioSession instance: \(error.localizedDescription)")
        }
    }

    private func handleNowPlayableItemChange(metadata: NowPlayableStaticMetadata) {
        setNowPlayingMetadata(metadata)
    }

    private func handleNowPlayablePlaybackChange(playing: Bool, metadata: NowPlayableDynamicMetadata) {
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
}
