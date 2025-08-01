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

// TODO: cleanup

class NowPlayableListener: MediaPlayerListener {

    private let logger = Logger.swiftfin()

    private var cancellables: Set<AnyCancellable> = []
    private var defaultRegisteredCommands: [NowPlayableCommand] {
        [
            .play,
            .pause,
            .togglePausePlay,
            .skipForward,
            .skipBackward,
            .changePlaybackPosition,
            .nextTrack,
            .previousTrack,
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

        try! handleNowPlayableConfiguration(
            commands: defaultRegisteredCommands,
            commandHandler: { _, _ in .success },
            interruptionHandler: { _ in }
        )

        setup(with: manager)
    }

    private func setup(with manager: MediaPlayerManager) {
        manager.$playbackItem.sink(receiveValue: itemDidChange).store(in: &cancellables)
        manager.secondsBox.$value.sink(receiveValue: secondsDidChange).store(in: &cancellables)
        manager.$state.sink(receiveValue: stateDidChange).store(in: &cancellables)
    }

    private func itemDidChange(newItem: MediaPlayerItem?) {
        guard let newItem else { return }

        handleNowPlayableItemChange(metadata: .init(mediaType: .video, title: newItem.baseItem.displayTitle))

        itemImageCancellable = Task {
            guard let image = await getNowPlayingImage(for: newItem) else { return }

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

    private func getNowPlayingImage(for item: MediaPlayerItem) async -> UIImage? {
        let imageRequests = item.baseItem.portraitImageSources(maxWidth: 100, quality: 90)
        return await ImagePipeline.Swiftfin.other.loadFirstImage(from: imageRequests)
    }

    private func secondsDidChange(newSeconds: Duration) {
        handleNowPlayablePlaybackChange(
            playing: true,
            metadata: .init(
                position: Float(newSeconds.seconds),
                duration: Float(manager?.item.runtime?.seconds ?? 0)
            )
        )
    }

    private func stateDidChange(newState: MediaPlayerManager.State) {
        handleNowPlayablePlaybackChange(
            playing: true,
            metadata: .init(
                position: 12,
                duration: 123
            )
        )
    }

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

    private func handleNowPlayableConfiguration(
        commands: [NowPlayableCommand],
        commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus,
        interruptionHandler: @escaping (NowPlayableInterruption) -> Void
    ) throws {
        try configureRemoteCommands(
            commands,
            commandHandler: commandHandler
        )
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
        commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent)
            -> MPRemoteCommandHandlerStatus
    ) throws {

        // Check that at least one command is being handled.

        guard commands.count > 1 else { throw NowPlayableError.noRegisteredCommands }

        // Configure each command.

        for command in commands {
            command.removeHandler()
            command.addHandler(commandHandler)
            command.setDisabled(false)
        }
    }

    // Set per-track metadata. Implementations of `handleNowPlayableItemChange(metadata:)`
    // will typically invoke this method.

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

    // Set playback info. Implementations of `handleNowPlayablePlaybackChange(playing:rate:position:duration:)`
    // will typically invoke this method.

    private func setNowPlayingPlaybackInfo(_ metadata: NowPlayableDynamicMetadata) {

        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo: [String: Any] = nowPlayingInfoCenter.nowPlayingInfo ?? [:]

        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = metadata.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = metadata.position
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = metadata.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyCurrentLanguageOptions] = metadata.currentLanguageOptions
        nowPlayingInfo[MPNowPlayingInfoPropertyAvailableLanguageOptions] = metadata.availableLanguageOptionGroups

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
}
