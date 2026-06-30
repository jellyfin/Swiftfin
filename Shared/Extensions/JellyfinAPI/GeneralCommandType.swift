//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension GeneralCommandType: Displayable, SystemImageable {

    // swiftlint:disable:next hard_coded_display_string
    var displayTitle: String {
        rawValue.reduce(into: .empty) { result, character in
            if character.isUppercase, let last = result.last, !last.isUppercase {
                result.append(" ")
            }
            result.append(character)
        }
    }

    var systemImage: String {
        switch self {
        case .moveUp:
            "chevron.up"
        case .moveDown:
            "chevron.down"
        case .moveLeft:
            "chevron.left"
        case .moveRight:
            "chevron.right"
        case .pageUp:
            "arrow.up.to.line"
        case .pageDown:
            "arrow.down.to.line"
        case .previousLetter:
            "textformat.abc"
        case .nextLetter:
            "textformat.abc"
        case .toggleOsd:
            "rectangle.bottomthird.inset.filled"
        case .toggleContextMenu:
            "contextualmenu.and.cursorarrow"
        case .select:
            "smallcircle.filled.circle"
        case .back:
            "arrow.uturn.backward"
        case .takeScreenshot:
            "camera"
        case .sendKey:
            "keyboard"
        case .sendString:
            "character.cursor.ibeam"
        case .goHome:
            "house"
        case .goToSettings:
            "gearshape"
        case .volumeUp:
            "speaker.wave.3"
        case .volumeDown:
            "speaker.wave.1"
        case .mute:
            "speaker.slash"
        case .unmute:
            "speaker.wave.2"
        case .toggleMute:
            "speaker.slash"
        case .setVolume:
            "speaker.wave.2"
        case .setAudioStreamIndex:
            "waveform"
        case .setSubtitleStreamIndex:
            "captions.bubble"
        case .toggleFullscreen:
            "arrow.up.left.and.arrow.down.right"
        case .displayContent:
            "rectangle.on.rectangle"
        case .goToSearch:
            "magnifyingglass"
        case .displayMessage:
            "message"
        case .setRepeatMode:
            "repeat"
        case .channelUp:
            "arrowtriangle.up"
        case .channelDown:
            "arrowtriangle.down"
        case .guide:
            "tv.and.mediabox"
        case .toggleStats:
            "chart.bar"
        case .playMediaSource:
            "play.rectangle"
        case .playTrailers:
            "film"
        case .setShuffleQueue:
            "shuffle"
        case .playState:
            "playpause"
        case .playNext:
            "text.line.first.and.arrowtriangle.forward"
        case .toggleOsdMenu:
            "slider.horizontal.below.rectangle"
        case .play:
            "play"
        case .setMaxStreamingBitrate:
            "speedometer"
        case .setPlaybackOrder:
            "list.number"
        }
    }
}
