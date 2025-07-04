//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// GeneralCommandType that require an Argument
enum GeneralCommandArgument: Equatable {
    case volume(Int)
    case audioStreamIndex(Int)
    case subtitleStreamIndex(Int)
    case key(String)
    case string(String)
    case repeatMode(RepeatMode)
    case playMediaSource(itemId: String, mediaSourceId: String? = nil, audioStreamIndex: Int? = nil, subtitleStreamIndex: Int? = nil)
    case playItems(itemIds: [String], startPositionTicks: Int64? = nil, playCommand: PlayCommand)
    case shuffleMode(Bool)
    case maxStreamingBitrate(Int64)
    case playbackOrder(PlaybackOrder)
    case displayContent(itemId: String, itemName: String, itemType: String)

    var arguments: [String: String] {
        switch self {
        case let .volume(value):
            return ["Volume": String(max(0, min(100, value)))]
        case let .audioStreamIndex(index):
            return ["Index": String(index)]
        case let .subtitleStreamIndex(index):
            return ["Index": String(index)]
        case let .key(key):
            return ["Key": key]
        case let .string(string):
            return ["String": string]
        case let .repeatMode(mode):
            return ["RepeatMode": mode.rawValue]
        case let .playMediaSource(itemId, mediaSourceId, audioStreamIndex, subtitleStreamIndex):
            var args = ["ItemId": itemId]
            if let mediaSourceId = mediaSourceId {
                args["MediaSourceId"] = mediaSourceId
            }
            if let audioStreamIndex = audioStreamIndex {
                args["AudioStreamIndex"] = String(audioStreamIndex)
            }
            if let subtitleStreamIndex = subtitleStreamIndex {
                args["SubtitleStreamIndex"] = String(subtitleStreamIndex)
            }
            return args
        case let .playItems(itemIds, startPositionTicks, playCommand):
            var args = ["ItemIds": itemIds.joined(separator: ","), "PlayCommand": playCommand.rawValue]
            if let startPositionTicks = startPositionTicks {
                args["StartPositionTicks"] = String(startPositionTicks)
            }
            return args
        case let .shuffleMode(shuffle):
            return ["ShuffleMode": shuffle ? "Shuffle" : "Sorted"]
        case let .maxStreamingBitrate(bitrate):
            return ["Bitrate": String(bitrate)]
        case let .playbackOrder(order):
            return ["PlaybackOrder": order.rawValue]
        case let .displayContent(itemId, itemName, itemType):
            return ["ItemId": itemId, "ItemName": itemName, "ItemType": itemType]
        }
    }
}
