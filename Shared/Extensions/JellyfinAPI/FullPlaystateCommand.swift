//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct FullPlaystateCommand: Equatable {
    private let command: PlaystateCommand
    private let seekPositionTicks: Int?

    // MARK: - Playstate Request

    func command(userID: String) -> PlaystateRequest {
        PlaystateRequest(
            command: command,
            controllingUserID: userID,
            seekPositionTicks: seekPositionTicks
        )
    }
}

extension FullPlaystateCommand {

    // MARK: - Default

    /// Creates a playstate command that doesn't require arguments
    /// - Parameter command: The playstate command (cannot be .seek)
    init(_ command: PlaystateCommand) {
        guard command != .seek else {
            preconditionFailure("Use init(seekPositionTicks:) for seek commands")
        }
        self.command = command
        self.seekPositionTicks = nil
    }

    // MARK: - PlaystateCommand.seek

    /// Creates a seek command to jump to a specific position
    /// - Parameter seekPositionTicks: Position to seek to in ticks (100 nanosecond units)
    init(seekPositionTicks: Int) {
        self.command = .seek
        self.seekPositionTicks = seekPositionTicks
    }
}
