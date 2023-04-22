//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import VLCUI

extension MediaStream {

    // TODO: Localize
    static var none: MediaStream = .init(displayTitle: "None", index: -1)

    var asPlaybackChild: VLCVideoPlayer.PlaybackChild? {
        guard let deliveryURL else { return nil }
        let client = Container.userSession.callAsFunction().client
        let deliveryPath = deliveryURL.removingFirst(if: client.configuration.url.absoluteString.last == "/")

        let fullURL = client.fullURL(with: deliveryPath)

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

    var size: String? {
        guard let height, let width else { return nil }
        return "\(width)x\(height)"
    }

    // MARK: Property groups

    var metadataProperties: [TextPair] {
        var properties: [TextPair] = []

        if let value = type {
            properties.append(.init(displayTitle: "Type", subtitle: value.rawValue))
        }

        if let value = codec {
            properties.append(.init(displayTitle: "Codec", subtitle: value))
        }

        if let value = codecTag {
            properties.append(.init(displayTitle: "Codec Tag", subtitle: value))
        }

        if let value = language {
            properties.append(.init(displayTitle: "Language", subtitle: value))
        }

        if let value = timeBase {
            properties.append(.init(displayTitle: "Time Base", subtitle: value))
        }

        if let value = codecTimeBase {
            properties.append(.init(displayTitle: "Codec Time Base", subtitle: value))
        }

        if let value = videoRange {
            properties.append(.init(displayTitle: "Video Range", subtitle: value))
        }

        if let value = isInterlaced {
            properties.append(.init(displayTitle: "Interlaced", subtitle: value.description))
        }

        if let value = isAVC {
            properties.append(.init(displayTitle: "AVC", subtitle: value.description))
        }

        if let value = channelLayout {
            properties.append(.init(displayTitle: "Channel Layout", subtitle: value))
        }

        if let value = bitRate {
            properties.append(.init(displayTitle: "Bitrate", subtitle: value.description))
        }

        if let value = bitDepth {
            properties.append(.init(displayTitle: "Bit Depth", subtitle: value.description))
        }

        if let value = refFrames {
            properties.append(.init(displayTitle: "Reference Frames", subtitle: value.description))
        }

        if let value = packetLength {
            properties.append(.init(displayTitle: "Packet Length", subtitle: value.description))
        }

        if let value = channels {
            properties.append(.init(displayTitle: "Channels", subtitle: value.description))
        }

        if let value = sampleRate {
            properties.append(.init(displayTitle: "Sample Rate", subtitle: value.description))
        }

        if let value = isDefault {
            properties.append(.init(displayTitle: "Default", subtitle: value.description))
        }

        if let value = isForced {
            properties.append(.init(displayTitle: "Forced", subtitle: value.description))
        }

        if let value = averageFrameRate {
            properties.append(.init(displayTitle: "Average Frame Rate", subtitle: value.description))
        }

        if let value = realFrameRate {
            properties.append(.init(displayTitle: "Real Frame Rate", subtitle: value.description))
        }

        if let value = profile {
            properties.append(.init(displayTitle: "Profile", subtitle: value))
        }

        if let value = aspectRatio {
            properties.append(.init(displayTitle: "Aspect Ratio", subtitle: value))
        }

        if let value = index {
            properties.append(.init(displayTitle: "Index", subtitle: value.description))
        }

        if let value = score {
            properties.append(.init(displayTitle: "Score", subtitle: value.description))
        }

        if let value = pixelFormat {
            properties.append(.init(displayTitle: "Pixel Format", subtitle: value))
        }

        if let value = level {
            properties.append(.init(displayTitle: "Level", subtitle: value.description))
        }

        if let value = isAnamorphic {
            properties.append(.init(displayTitle: "Anamorphic", subtitle: value.description))
        }

        return properties
    }

    var colorProperties: [TextPair] {
        var properties: [TextPair] = []

        if let value = colorRange {
            properties.append(.init(displayTitle: "Range", subtitle: value))
        }

        if let value = colorSpace {
            properties.append(.init(displayTitle: "Space", subtitle: value))
        }

        if let value = colorTransfer {
            properties.append(.init(displayTitle: "Transfer", subtitle: value))
        }

        if let value = colorPrimaries {
            properties.append(.init(displayTitle: "Primaries", subtitle: value))
        }

        return properties
    }

    var deliveryProperties: [TextPair] {
        var properties: [TextPair] = []

        if let value = isExternal {
            properties.append(.init(displayTitle: "External", subtitle: value.description))
        }

        if let value = deliveryMethod {
            properties.append(.init(displayTitle: "Delivery Method", subtitle: value.rawValue))
        }

        if let value = deliveryURL {
            properties.append(.init(displayTitle: "URL", subtitle: value))
        }

        if let value = deliveryURL {
            properties.append(.init(displayTitle: "External URL", subtitle: value.description))
        }

        if let value = isTextSubtitleStream {
            properties.append(.init(displayTitle: "Text Subtitle", subtitle: value.description))
        }

        if let value = path {
            properties.append(.init(displayTitle: "Path", subtitle: value))
        }

        return properties
    }
}

extension [MediaStream] {

    func adjustExternalSubtitleIndexes(audioStreamCount: Int) -> [MediaStream] {
        guard allSatisfy({ $0.type == .subtitle }) else { return self }
        let embeddedSubtitleCount = filter { !($0.isExternal ?? false) }.count

        var mediaStreams = self

        for (i, mediaStream) in mediaStreams.enumerated() {
            guard mediaStream.isExternal ?? false else { continue }
            var _mediaStream = mediaStream
            _mediaStream.index = 1 + embeddedSubtitleCount + audioStreamCount

            mediaStreams[i] = _mediaStream
        }

        return mediaStreams
    }

    func adjustAudioForExternalSubtitles(externalMediaStreamCount: Int) -> [MediaStream] {
        guard allSatisfy({ $0.type == .audio }) else { return self }

        var mediaStreams = self

        for (i, mediaStream) in mediaStreams.enumerated() {
            var copy = mediaStream
            copy.index = (copy.index ?? 0) - externalMediaStreamCount
            mediaStreams[i] = copy
        }

        return mediaStreams
    }

    var has4KVideo: Bool {
        first(where: { $0.is4kVideo }) != nil
    }

    var has51AudioChannelLayout: Bool {
        first(where: { $0.is51AudioChannelLayout }) != nil
    }

    var has71AudioChannelLayout: Bool {
        first(where: { $0.is71AudioChannelLayout }) != nil
    }

    var hasHDVideo: Bool {
        first(where: { $0.isHDVideo }) != nil
    }

    var hasSubtitles: Bool {
        first(where: { $0.type == .subtitle }) != nil
    }
}
