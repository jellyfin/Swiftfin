//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import VLCUI

extension MediaStream {

    static var none: MediaStream = .init(displayTitle: L10n.none, index: -1)

    var asPlaybackChild: VLCVideoPlayer.PlaybackChild? {
        guard let deliveryURL, let client = Container.shared.currentUserSession()?.client else { return nil }

        let deliveryPath = deliveryURL.removingFirst(if: client.configuration.url.absoluteString.last == "/")

        guard let fullURL = client.fullURL(with: deliveryPath) else { return nil }

        return .init(
            url: fullURL,
            type: .subtitle,
            enforce: false
        )
    }

    var is4kVideo: Bool {
        (width ?? 0) > 3800 && type == .video
    }

    var is51AudioChannelLayout: Bool {
        channelLayout == "5.1"
    }

    var is71AudioChannelLayout: Bool {
        channelLayout == "7.1"
    }

    var isHDVideo: Bool {
        (width ?? 0) > 1900 && type == .video
    }

    // MARK: Property groups

    var metadataProperties: [TextPair] {
        var properties: [TextPair] = []

        if let value = type {
            properties.append(.init(title: "Type", subtitle: value.rawValue))
        }

        if let value = codec {
            properties.append(.init(title: "Codec", subtitle: value))
        }

        if let value = codecTag {
            properties.append(.init(title: "Codec Tag", subtitle: value))
        }

        if let value = language {
            properties.append(.init(title: "Language", subtitle: value))
        }

        if let value = timeBase {
            properties.append(.init(title: "Time Base", subtitle: value))
        }

        if let value = codecTimeBase {
            properties.append(.init(title: "Codec Time Base", subtitle: value))
        }

        if let value = videoRange {
            properties.append(.init(title: "Video Range", subtitle: value))
        }

        if let value = isInterlaced {
            properties.append(.init(title: "Interlaced", subtitle: value.description))
        }

        if let value = isAVC {
            properties.append(.init(title: "AVC", subtitle: value.description))
        }

        if let value = channelLayout {
            properties.append(.init(title: "Channel Layout", subtitle: value))
        }

        if let value = bitRate {
            properties.append(.init(title: "Bitrate", subtitle: value.description))
        }

        if let value = bitDepth {
            properties.append(.init(title: "Bit Depth", subtitle: value.description))
        }

        if let value = refFrames {
            properties.append(.init(title: "Reference Frames", subtitle: value.description))
        }

        if let value = packetLength {
            properties.append(.init(title: "Packet Length", subtitle: value.description))
        }

        if let value = channels {
            properties.append(.init(title: "Channels", subtitle: value.description))
        }

        if let value = sampleRate {
            properties.append(.init(title: "Sample Rate", subtitle: value.description))
        }

        if let value = isDefault {
            properties.append(.init(title: "Default", subtitle: value.description))
        }

        if let value = isForced {
            properties.append(.init(title: "Forced", subtitle: value.description))
        }

        if let value = averageFrameRate {
            properties.append(.init(title: "Average Frame Rate", subtitle: value.description))
        }

        if let value = realFrameRate {
            properties.append(.init(title: "Real Frame Rate", subtitle: value.description))
        }

        if let value = profile {
            properties.append(.init(title: "Profile", subtitle: value))
        }

        if let value = aspectRatio {
            properties.append(.init(title: "Aspect Ratio", subtitle: value))
        }

        if let value = index {
            properties.append(.init(title: "Index", subtitle: value.description))
        }

        if let value = score {
            properties.append(.init(title: "Score", subtitle: value.description))
        }

        if let value = pixelFormat {
            properties.append(.init(title: "Pixel Format", subtitle: value))
        }

        if let value = level {
            properties.append(.init(title: "Level", subtitle: value.description))
        }

        if let value = isAnamorphic {
            properties.append(.init(title: "Anamorphic", subtitle: value.description))
        }

        return properties
    }

    var colorProperties: [TextPair] {
        var properties: [TextPair] = []

        if let value = colorRange {
            properties.append(.init(title: "Range", subtitle: value))
        }

        if let value = colorSpace {
            properties.append(.init(title: "Space", subtitle: value))
        }

        if let value = colorTransfer {
            properties.append(.init(title: "Transfer", subtitle: value))
        }

        if let value = colorPrimaries {
            properties.append(.init(title: "Primaries", subtitle: value))
        }

        return properties
    }

    var deliveryProperties: [TextPair] {
        var properties: [TextPair] = []

        if let value = isExternal {
            properties.append(.init(title: "External", subtitle: value.description))
        }

        if let value = deliveryMethod {
            properties.append(.init(title: "Delivery Method", subtitle: value.rawValue))
        }

        if let value = deliveryURL {
            properties.append(.init(title: "URL", subtitle: value))
        }

        if let value = deliveryURL {
            properties.append(.init(title: "External URL", subtitle: value.description))
        }

        if let value = isTextSubtitleStream {
            properties.append(.init(title: "Text Subtitle", subtitle: value.description))
        }

        if let value = path {
            properties.append(.init(title: "Path", subtitle: value))
        }

        return properties
    }
}

extension [MediaStream] {

    /// What is this?
    /// Jellyfin maintains a sequential indexing system across all tracks with external at the beginning
    /// VLCKit handles external tracks (added separately to the media) by appending them to the end of the track list
    /// These functions change the order of the track list to reflect VLCKit's expected order

    /// Adjust track indexes based on the a count of external tracks
    func adjustedAudio(
        for streamType: StreamType,
        embeddedSubtitleCount: Int,
        externalSubtitleCount: Int
    ) -> [MediaStream] {
        guard allSatisfy({ $0.type == .audio }) else { return self }

        let embeddedAudioCount = filter { $0.isExternal == false }.count
        let externalAudioCount = filter { $0.isExternal == true }.count

        var mediaStreams = self

        for (i, mediaStream) in mediaStreams.enumerated() {
            var copy = mediaStream

            switch streamType {
            case .direct, .hls:
                if copy.isExternal ?? false {
                    // Move external tracks to the end
                    copy.index = (copy.index ?? 0) + embeddedSubtitleCount + embeddedAudioCount
                } else {
                    // Move internal tracks to the beginning
                    copy.index = (copy.index ?? 0) - (externalAudioCount + externalSubtitleCount)
                }
                mediaStreams[i] = copy
            default:
                // TODO: Transcode Audio Tracks will need something like: https://github.com/jellyfin/jellyfin-web/blob/master/src/components/playback/playbackmanager.js#L1691
                break
            }
        }
        return mediaStreams
    }

    /// Adjust track indexes based on the a count of external tracks
    func adjustedSubtitles(
        for streamType: StreamType,
        embeddedAudioCount: Int,
        externalAudioCount: Int
    ) -> [MediaStream] {
        guard allSatisfy({ $0.type == .subtitle }) else { return self }

        let embeddedSubtitleCount = filter { !($0.isExternal ?? false) }.count
        let externalSubtitleCount = filter { $0.isExternal ?? false }.count

        var mediaStreams = self
        var subtitleCounter = 0

        for (i, mediaStream) in mediaStreams.enumerated() {
            var copy = mediaStream

            switch streamType {
            case .direct, .hls:
                if copy.isExternal ?? false {
                    // Move external tracks to the end
                    copy.index = (copy.index ?? 0) + embeddedSubtitleCount + embeddedAudioCount + externalAudioCount
                } else {
                    // Move internal tracks to the beginning
                    copy.index = (copy.index ?? 0) - (externalAudioCount + externalSubtitleCount)
                }
            default:
                // In transcoded streams, video is 0, audio is 1, and subtitles start at 2
                let subtitleBaseIndex = 2

                // Assign a sequential index for subtitles starting from subtitleBaseIndex
                copy.index = subtitleBaseIndex + subtitleCounter
                subtitleCounter += 1
            }
            mediaStreams[i] = copy
        }
        return mediaStreams
    }

    var has4KVideo: Bool {
        contains { $0.is4kVideo }
    }

    var has51AudioChannelLayout: Bool {
        contains { $0.is51AudioChannelLayout }
    }

    var has71AudioChannelLayout: Bool {
        contains { $0.is71AudioChannelLayout }
    }

    var hasHDVideo: Bool {
        contains { $0.isHDVideo }
    }

    var hasSubtitles: Bool {
        contains { $0.type == .subtitle }
    }
}
