//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

protocol CommandConvertible {
    func toGeneralCommand(userID: String) -> GeneralCommand
}

enum SendGeneralCommand: Equatable {
    case moveUp
    case moveDown
    case moveLeft
    case moveRight
    case pageUp
    case pageDown
    case previousLetter
    case nextLetter
    case toggleOsd
    case toggleContextMenu
    case select
    case back
    case takeScreenshot
    case goHome
    case goToSettings
    case volumeUp
    case volumeDown
    case mute
    case unmute
    case toggleMute
    case toggleFullscreen
    case goToSearch
    case channelUp
    case channelDown
    case guide
    case toggleStats
    case playTrailers
    case playNext
    case toggleOsdMenu
    case play

    case setVolume(level: Int)
    case setAudioStreamIndex(index: Int)
    case setSubtitleStreamIndex(index: Int)
    case sendKey(key: String)
    case sendString(string: String)
    case displayMessage(message: String)
    case setRepeatMode(mode: RepeatMode)
    case setShuffleQueue(shuffle: Bool)
    case setMaxStreamingBitrate(bitrate: Int64)
    case setPlaybackOrder(order: PlaybackOrder)

    case playMediaSource(
        itemId: String,
        mediaSourceId: String? = nil,
        audioStreamIndex: Int? = nil,
        subtitleStreamIndex: Int? = nil
    )

    case playItems(
        itemIds: [String],
        startPositionTicks: Int64? = nil,
        playCommand: PlayCommand
    )

    case displayContent(
        itemId: String,
        itemName: String,
        itemType: String
    )
}

extension SendGeneralCommand: CommandConvertible {

    private var commandType: GeneralCommandType {
        switch self {
        case .back:
            return .back
        case .channelDown:
            return .channelDown
        case .channelUp:
            return .channelUp
        case .displayContent:
            return .displayContent
        case .displayMessage:
            return .displayMessage
        case .goHome:
            return .goHome
        case .goToSearch:
            return .goToSearch
        case .goToSettings:
            return .goToSettings
        case .guide:
            return .guide
        case .moveDown:
            return .moveDown
        case .moveLeft:
            return .moveLeft
        case .moveRight:
            return .moveRight
        case .moveUp:
            return .moveUp
        case .mute:
            return .mute
        case .nextLetter:
            return .nextLetter
        case .pageDown:
            return .pageDown
        case .pageUp:
            return .pageUp
        case .play:
            return .play
        case .playItems:
            return .playState
        case .playMediaSource:
            return .playMediaSource
        case .playNext:
            return .playNext
        case .playTrailers:
            return .playTrailers
        case .previousLetter:
            return .previousLetter
        case .select:
            return .select
        case .sendKey:
            return .sendKey
        case .sendString:
            return .sendString
        case .setAudioStreamIndex:
            return .setAudioStreamIndex
        case .setMaxStreamingBitrate:
            return .setMaxStreamingBitrate
        case .setPlaybackOrder:
            return .setPlaybackOrder
        case .setRepeatMode:
            return .setRepeatMode
        case .setShuffleQueue:
            return .setShuffleQueue
        case .setSubtitleStreamIndex:
            return .setSubtitleStreamIndex
        case .setVolume:
            return .setVolume
        case .takeScreenshot:
            return .takeScreenshot
        case .toggleContextMenu:
            return .toggleContextMenu
        case .toggleFullscreen:
            return .toggleFullscreen
        case .toggleMute:
            return .toggleMute
        case .toggleOsd:
            return .toggleOsd
        case .toggleOsdMenu:
            return .toggleOsdMenu
        case .toggleStats:
            return .toggleStats
        case .unmute:
            return .unmute
        case .volumeDown:
            return .volumeDown
        case .volumeUp:
            return .volumeUp
        }
    }

    private var arguments: [String: String]? {
        switch self {
        case .moveUp, .moveDown, .moveLeft, .moveRight, .pageUp, .pageDown,
             .previousLetter, .nextLetter, .toggleOsd, .toggleContextMenu,
             .select, .back, .takeScreenshot, .goHome, .goToSettings,
             .volumeUp, .volumeDown, .mute, .unmute, .toggleMute,
             .toggleFullscreen, .goToSearch, .channelUp, .channelDown,
             .guide, .toggleStats, .playTrailers, .playNext, .toggleOsdMenu, .play:
            return nil

        case let .setVolume(level):
            return ["Volume": String(max(0, min(100, level)))]

        case let .setAudioStreamIndex(index):
            return ["Index": String(index)]

        case let .setSubtitleStreamIndex(index):
            return ["Index": String(index)]

        case let .sendKey(key):
            return ["Key": key]

        case let .sendString(string):
            return ["String": string]

        case let .displayMessage(message):
            return ["String": message]

        case let .setRepeatMode(mode):
            return ["RepeatMode": mode.rawValue]

        case let .setShuffleQueue(shuffle):
            return ["ShuffleMode": shuffle ? "Shuffle" : "Sorted"]

        case let .setMaxStreamingBitrate(bitrate):
            return ["Bitrate": String(bitrate)]

        case let .setPlaybackOrder(order):
            return ["PlaybackOrder": order.rawValue]

        case let .playMediaSource(itemId, mediaSourceId, audioStreamIndex, subtitleStreamIndex):
            var result = ["ItemId": itemId]
            if let mediaSourceId {
                result["MediaSourceId"] = mediaSourceId
            }
            if let audioStreamIndex {
                result["AudioStreamIndex"] = String(audioStreamIndex)
            }
            if let subtitleStreamIndex {
                result["SubtitleStreamIndex"] = String(subtitleStreamIndex)
            }
            return result

        case let .playItems(itemIds, startPositionTicks, playCommand):
            var result = [
                "ItemIds": itemIds.joined(separator: ","),
                "PlayCommand": playCommand.rawValue,
            ]
            if let startPositionTicks {
                result["StartPositionTicks"] = String(startPositionTicks)
            }
            return result

        case let .displayContent(itemId, itemName, itemType):
            return [
                "ItemId": itemId,
                "ItemName": itemName,
                "ItemType": itemType,
            ]
        }
    }

    func toGeneralCommand(userID: String) -> GeneralCommand {
        GeneralCommand(
            arguments: arguments,
            controllingUserID: userID,
            name: commandType
        )
    }
}

extension SendGeneralCommand {

    static func volume(_ level: Int) -> SendGeneralCommand {
        .setVolume(level: level)
    }

    static func audioStream(_ index: Int) -> SendGeneralCommand {
        .setAudioStreamIndex(index: index)
    }

    static func subtitleStream(_ index: Int) -> SendGeneralCommand {
        .setSubtitleStreamIndex(index: index)
    }

    static func key(_ key: String) -> SendGeneralCommand {
        .sendKey(key: key)
    }

    static func string(_ string: String) -> SendGeneralCommand {
        .sendString(string: string)
    }

    static func message(_ message: String) -> SendGeneralCommand {
        .displayMessage(message: message)
    }

    static func repeatMode(_ mode: RepeatMode) -> SendGeneralCommand {
        .setRepeatMode(mode: mode)
    }

    static func shuffle(_ enabled: Bool) -> SendGeneralCommand {
        .setShuffleQueue(shuffle: enabled)
    }

    static func maxBitrate(_ bitrate: Int64) -> SendGeneralCommand {
        .setMaxStreamingBitrate(bitrate: bitrate)
    }

    static func playbackOrder(_ order: PlaybackOrder) -> SendGeneralCommand {
        .setPlaybackOrder(order: order)
    }
}
