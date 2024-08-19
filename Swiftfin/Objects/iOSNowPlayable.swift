//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import MediaPlayer

class IOSNowPlayable: NowPlayable {

    static var shared: IOSNowPlayable = IOSNowPlayable()

    var defaultRegisteredCommands: [NowPlayableCommand] {
        [
            .togglePausePlay,
            .play,
            .pause,
            .skipForward(10.0),
            .skipBackward(10.0),
        ]
    }

    func handleNowPlayableConfiguration(
        commands: [NowPlayableCommand],
        disabledCommands: [NowPlayableCommand],
        commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus,
        interruptionHandler: @escaping (NowPlayableInterruption) -> Void
    ) throws {
        try configureRemoteCommands(
            commands,
            disabledCommands: [],
            commandHandler: commandHandler
        )
    }

    func handleNowPlayableSessionStart() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
    }

    func handleNowPlayableSessionEnd() {
        try! AVAudioSession.sharedInstance().setActive(false)
    }

    func handleNowPlayableItemChange(metadata: NowPlayableStaticMetadata) {
        setNowPlayingMetadata(metadata)
    }

    func handleNowPlayablePlaybackChange(playing: Bool, metadata: NowPlayableDynamicMetadata) {
        setNowPlayingPlaybackInfo(metadata)
    }
}
