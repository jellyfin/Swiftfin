//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

protocol PlaystateCommandConvertible {
    func toPlaystateRequest(userID: String) -> PlaystateRequest
}

enum SendPlaystateCommand: Equatable {
    case stop
    case pause
    case unpause
    case nextTrack
    case previousTrack
    case rewind
    case fastForward
    case playPause
    case seek(positionTicks: Int)
}

extension SendPlaystateCommand: PlaystateCommandConvertible {

    private var playstateCommand: PlaystateCommand {
        switch self {
        case .fastForward:
            return .fastForward
        case .nextTrack:
            return .nextTrack
        case .pause:
            return .pause
        case .playPause:
            return .playPause
        case .previousTrack:
            return .previousTrack
        case .rewind:
            return .rewind
        case .seek:
            return .seek
        case .stop:
            return .stop
        case .unpause:
            return .unpause
        }
    }

    private var seekPositionTicks: Int? {
        switch self {
        case let .seek(positionTicks):
            return positionTicks
        case .stop, .pause, .unpause, .nextTrack, .previousTrack, .rewind, .fastForward, .playPause:
            return nil
        }
    }

    func toPlaystateRequest(userID: String) -> PlaystateRequest {
        PlaystateRequest(
            command: playstateCommand,
            controllingUserID: userID,
            seekPositionTicks: seekPositionTicks
        )
    }
}

extension SendPlaystateCommand {

    /// Creates a seek command from ticks (100 nanosecond units)
    static func seekTo(_ ticks: Int) -> SendPlaystateCommand {
        .seek(positionTicks: ticks)
    }

    /// Creates a seek command from seconds
    static func seekTo(seconds: Double) -> SendPlaystateCommand {
        let ticks = Int(seconds * 10_000_000)
        return .seek(positionTicks: ticks)
    }

    /// Creates a seek command from milliseconds
    static func seekTo(milliseconds: Int) -> SendPlaystateCommand {
        let ticks = milliseconds * 10000
        return .seek(positionTicks: ticks)
    }
}
