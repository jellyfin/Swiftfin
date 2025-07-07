//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct FullGeneralCommand: Equatable {
    private let command: GeneralCommandType
    private let volumeLevel: Int?
    private let streamIndex: Int?
    private let keyValue: String?
    private let stringValue: String?
    private let repeatMode: RepeatMode?
    private let itemId: String?
    private let mediaSourceId: String?
    private let audioStreamIndex: Int?
    private let subtitleStreamIndex: Int?
    private let itemIds: [String]?
    private let startPositionTicks: Int64?
    private let playCommand: PlayCommand?
    private let shuffleMode: Bool?
    private let maxBitrate: Int64?
    private let playbackOrder: PlaybackOrder?
    private let itemName: String?
    private let itemType: String?

    // MARK: - Initializer

    private init(
        command: GeneralCommandType,
        volumeLevel: Int? = nil,
        streamIndex: Int? = nil,
        keyValue: String? = nil,
        stringValue: String? = nil,
        repeatMode: RepeatMode? = nil,
        itemId: String? = nil,
        mediaSourceId: String? = nil,
        audioStreamIndex: Int? = nil,
        subtitleStreamIndex: Int? = nil,
        itemIds: [String]? = nil,
        startPositionTicks: Int64? = nil,
        playCommand: PlayCommand? = nil,
        shuffleMode: Bool? = nil,
        maxBitrate: Int64? = nil,
        playbackOrder: PlaybackOrder? = nil,
        itemName: String? = nil,
        itemType: String? = nil
    ) {
        self.command = command
        self.volumeLevel = volumeLevel
        self.streamIndex = streamIndex
        self.keyValue = keyValue
        self.stringValue = stringValue
        self.repeatMode = repeatMode
        self.itemId = itemId
        self.mediaSourceId = mediaSourceId
        self.audioStreamIndex = audioStreamIndex
        self.subtitleStreamIndex = subtitleStreamIndex
        self.itemIds = itemIds
        self.startPositionTicks = startPositionTicks
        self.playCommand = playCommand
        self.shuffleMode = shuffleMode
        self.maxBitrate = maxBitrate
        self.playbackOrder = playbackOrder
        self.itemName = itemName
        self.itemType = itemType
    }

    // MARK: - General Command Arguments

    private var arguments: [String: String]? {
        switch command {
        case .setVolume:
            guard let volumeLevel else { return nil }
            return ["Volume": String(max(0, min(100, volumeLevel)))]
        case .setAudioStreamIndex:
            guard let streamIndex else { return nil }
            return ["Index": String(streamIndex)]
        case .setSubtitleStreamIndex:
            guard let streamIndex else { return nil }
            return ["Index": String(streamIndex)]
        case .sendKey:
            guard let keyValue else { return nil }
            return ["Key": keyValue]
        case .sendString:
            guard let stringValue else { return nil }
            return ["String": stringValue]
        case .setRepeatMode:
            guard let repeatMode else { return nil }
            return ["RepeatMode": repeatMode.rawValue]
        case .playMediaSource:
            guard let itemId else { return nil }
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
        case .playState:
            guard let itemIds, let playCommand else { return nil }
            var result = ["ItemIds": itemIds.joined(separator: ","), "PlayCommand": playCommand.rawValue]
            if let startPositionTicks {
                result["StartPositionTicks"] = String(startPositionTicks)
            }
            return result
        case .setShuffleQueue:
            guard let shuffleMode else { return nil }
            return ["ShuffleMode": shuffleMode ? "Shuffle" : "Sorted"]
        case .setMaxStreamingBitrate:
            guard let maxBitrate else { return nil }
            return ["Bitrate": String(maxBitrate)]
        case .setPlaybackOrder:
            guard let playbackOrder else { return nil }
            return ["PlaybackOrder": playbackOrder.rawValue]
        case .displayContent:
            guard let itemId, let itemName, let itemType else { return nil }
            return ["ItemId": itemId, "ItemName": itemName, "ItemType": itemType]
        case .displayMessage:
            guard let stringValue else { return nil }
            return ["String": stringValue]
        default:
            return nil
        }
    }

    // MARK: - General Command

    func command(userID: String) -> GeneralCommand {
        GeneralCommand(
            arguments: arguments,
            controllingUserID: userID,
            name: command
        )
    }
}

extension FullGeneralCommand {

    // MARK: - Commands without arguments

    /// Creates a general command that doesn't require any arguments
    /// - Parameter command: The command type (must not require arguments)
    init(_ command: GeneralCommandType) {
        guard !command.requiresArguments else {
            preconditionFailure("Command \(command) requires arguments")
        }
        self.init(command: command)
    }

    // MARK: - Volume

    /// Sets the volume level
    /// - Parameter volume: Volume level (0-100)
    init(volume: Int) {
        self.init(command: .setVolume, volumeLevel: volume)
    }

    // MARK: - Stream indices

    /// Sets the audio stream index
    /// - Parameter audioStreamIndex: Index of the audio stream
    init(audioStreamIndex: Int) {
        self.init(command: .setAudioStreamIndex, streamIndex: audioStreamIndex)
    }

    /// Sets the subtitle stream index
    /// - Parameter subtitleStreamIndex: Index of the subtitle stream
    init(subtitleStreamIndex: Int) {
        self.init(command: .setSubtitleStreamIndex, streamIndex: subtitleStreamIndex)
    }

    // MARK: - Keys and strings

    /// Sends a key command
    /// - Parameter key: The key to send
    init(key: String) {
        self.init(command: .sendKey, keyValue: key)
    }

    /// Sends a string command
    /// - Parameter string: The string to send
    init(string: String) {
        self.init(command: .sendString, stringValue: string)
    }

    /// Displays a message
    /// - Parameter message: The message to display
    init(message: String) {
        self.init(command: .displayMessage, stringValue: message)
    }

    // MARK: - Modes and settings

    /// Sets the repeat mode
    /// - Parameter repeatMode: The repeat mode to set
    init(repeatMode: RepeatMode) {
        self.init(command: .setRepeatMode, repeatMode: repeatMode)
    }

    /// Sets the shuffle mode
    /// - Parameter shuffleMode: True for shuffle, false for sorted
    init(shuffleMode: Bool) {
        self.init(command: .setShuffleQueue, shuffleMode: shuffleMode)
    }

    /// Sets the maximum streaming bitrate
    /// - Parameter maxBitrate: Maximum bitrate in bits per second
    init(maxBitrate: Int64) {
        self.init(command: .setMaxStreamingBitrate, maxBitrate: maxBitrate)
    }

    /// Sets the playback order
    /// - Parameter playbackOrder: The playback order to set
    init(playbackOrder: PlaybackOrder) {
        self.init(command: .setPlaybackOrder, playbackOrder: playbackOrder)
    }

    // MARK: - Complex commands

    /// Plays a media source
    /// - Parameters:
    ///   - itemId: The item ID to play
    ///   - mediaSourceId: Optional media source ID
    ///   - audioStreamIndex: Optional audio stream index
    ///   - subtitleStreamIndex: Optional subtitle stream index
    init(playMediaSource itemId: String, mediaSourceId: String? = nil, audioStreamIndex: Int? = nil, subtitleStreamIndex: Int? = nil) {
        self.init(
            command: .playMediaSource,
            itemId: itemId,
            mediaSourceId: mediaSourceId,
            audioStreamIndex: audioStreamIndex,
            subtitleStreamIndex: subtitleStreamIndex
        )
    }

    /// Plays a list of items
    /// - Parameters:
    ///   - itemIds: Array of item IDs to play
    ///   - startPositionTicks: Optional start position in ticks
    ///   - playCommand: The play command to use
    init(playItems itemIds: [String], startPositionTicks: Int64? = nil, playCommand: PlayCommand) {
        self.init(
            command: .playState,
            itemIds: itemIds,
            startPositionTicks: startPositionTicks,
            playCommand: playCommand
        )
    }

    /// Displays content information
    /// - Parameters:
    ///   - itemId: The item ID
    ///   - itemName: The item name
    ///   - itemType: The item type
    init(displayContent itemId: String, itemName: String, itemType: String) {
        self.init(
            command: .displayContent,
            itemId: itemId,
            itemName: itemName,
            itemType: itemType
        )
    }
}
