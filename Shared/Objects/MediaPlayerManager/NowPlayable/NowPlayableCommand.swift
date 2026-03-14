//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import MediaPlayer

enum NowPlayableCommand: CaseIterable {

    // Play/Pause
    case pause
    case play
    case stop
    case togglePausePlay

    // Track
    case nextTrack
    case previousTrack
    case changeRepeatMode
    case changeShuffleMode

    // Seeking/Rate
    case changePlaybackRate
    case seekBackward
    case seekForward
    case skipBackward
    case skipForward
    case changePlaybackPosition

    // Like/Dislike
    case rating
    case like
    case dislike

    // Bookmark
    case bookmark

    // Languages
    case enableLanguageOption
    case disableLanguageOption

    var remoteCommand: MPRemoteCommand {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        switch self {
        case .pause:
            return remoteCommandCenter.pauseCommand
        case .play:
            return remoteCommandCenter.playCommand
        case .stop:
            return remoteCommandCenter.stopCommand
        case .togglePausePlay:
            return remoteCommandCenter.togglePlayPauseCommand
        case .nextTrack:
            return remoteCommandCenter.nextTrackCommand
        case .previousTrack:
            return remoteCommandCenter.previousTrackCommand
        case .changeRepeatMode:
            return remoteCommandCenter.changeRepeatModeCommand
        case .changeShuffleMode:
            return remoteCommandCenter.changeShuffleModeCommand
        case .changePlaybackRate:
            return remoteCommandCenter.changePlaybackRateCommand
        case .seekBackward:
            return remoteCommandCenter.seekBackwardCommand
        case .seekForward:
            return remoteCommandCenter.seekForwardCommand
        case .skipBackward:
            return remoteCommandCenter.skipBackwardCommand
        case .skipForward:
            return remoteCommandCenter.skipForwardCommand
        case .changePlaybackPosition:
            return remoteCommandCenter.changePlaybackPositionCommand
        case .rating:
            return remoteCommandCenter.ratingCommand
        case .like:
            return remoteCommandCenter.likeCommand
        case .dislike:
            return remoteCommandCenter.dislikeCommand
        case .bookmark:
            return remoteCommandCenter.bookmarkCommand
        case .enableLanguageOption:
            return remoteCommandCenter.enableLanguageOptionCommand
        case .disableLanguageOption:
            return remoteCommandCenter.disableLanguageOptionCommand
        }
    }

    func removeHandler() {
        remoteCommand.removeTarget(nil)
    }

    func addHandler(_ handler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) {

        remoteCommand.removeTarget(nil)

        switch self {
        case .skipBackward:
            MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [15.0]
        case .skipForward:
            MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [15.0]
        default: ()
        }

        remoteCommand.addTarget { handler(self, $0) }
    }

    func isEnabled(_ isEnabled: Bool) {
        remoteCommand.isEnabled = isEnabled
    }
}
