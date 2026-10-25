//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import MediaPlayer

enum NowPlayableCommand: CaseIterable, Hashable, Sendable {

    enum Action {

        case play
        case pause
        case stop
        case togglePausePlay
        case nextTrack
        case previousTrack
        case skip(Duration)
        case seek(Duration)
        case rate(Double)
        case language(MPNowPlayingInfoLanguageOption, enabled: Bool)
    }

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

    func action(for event: MPRemoteCommandEvent) -> Action? {
        switch self {
        case .play:
            return .play

        case .pause:
            return .pause

        case .stop:
            return .stop

        case .togglePausePlay:
            return .togglePausePlay

        case .nextTrack:
            return .nextTrack

        case .previousTrack:
            return .previousTrack

        case .skipBackward, .skipForward:
            guard let event = event as? MPSkipIntervalCommandEvent, event.interval.isFinite, event.interval > 0 else { return nil }

            return .skip(.seconds(self == .skipBackward ? -event.interval : event.interval))

        case .changePlaybackPosition:
            guard let event = event as? MPChangePlaybackPositionCommandEvent, event.positionTime.isFinite else { return nil }

            return .seek(.seconds(event.positionTime))

        case .changePlaybackRate:
            guard let event = event as? MPChangePlaybackRateCommandEvent else { return nil }

            return .rate(Double(event.playbackRate))

        case .enableLanguageOption, .disableLanguageOption:
            guard let event = event as? MPChangeLanguageOptionCommandEvent else { return nil }

            return .language(event.languageOption, enabled: self == .enableLanguageOption)

        default:
            return nil
        }
    }

    @MainActor
    func addHandler(_ handler: @escaping @MainActor @Sendable (Action) -> MPRemoteCommandHandlerStatus) -> Any {
        switch self {
        case .skipBackward:
            MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [15.0]
        case .skipForward:
            MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [15.0]
        default:
            ()
        }

        return remoteCommand.addTarget { @Sendable event in
            // Remote commands can arrive outside the main actor. Return the actual result synchronously.
            if Thread.isMainThread {
                return MainActor.assumeIsolated {
                    guard let action = action(for: event) else { return .commandFailed }

                    return handler(action)
                }
            }

            return DispatchQueue.main.sync {
                guard let action = action(for: event) else { return .commandFailed }

                return handler(action)
            }
        }
    }

    func isEnabled(_ isEnabled: Bool) {
        remoteCommand.isEnabled = isEnabled
    }
}
