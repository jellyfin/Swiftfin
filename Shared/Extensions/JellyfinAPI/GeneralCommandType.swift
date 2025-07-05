//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension GeneralCommandType {

    static let commandsWithoutArguments: Set<GeneralCommandType> = [
        .moveUp, .moveDown, .moveLeft, .moveRight,
        .pageUp, .pageDown, .previousLetter, .nextLetter,
        .toggleOsd, .toggleContextMenu, .select, .back,
        .takeScreenshot, .goHome, .goToSettings,
        .volumeUp, .volumeDown, .mute, .unmute, .toggleMute,
        .toggleFullscreen, .goToSearch,
        .channelUp, .channelDown, .guide, .toggleStats,
        .playTrailers, .playNext, .toggleOsdMenu,
    ]

    var requiresArguments: Bool {
        !Self.commandsWithoutArguments.contains(self)
    }
}
