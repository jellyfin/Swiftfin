//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import VLCUI

struct TextPairItem: Displayable, Identifiable {

    let displayTitle: String
    let value: String

    var id: String {
        displayTitle.appending(value)
    }
}

extension MediaStream {

    func externalURL(base: String) -> URL? {
        var base = base
        while base.last == Character("/") {
            base.removeLast()
        }
        guard let deliveryURL = deliveryUrl else { return nil }
        return URL(string: base + deliveryURL)
    }

    var asPlaybackChild: VLCVideoPlayer.PlaybackChild? {
        guard let url = externalURL(base: SessionManager.main.currentLogin.server.currentURI) else { return nil }
        return .init(
            url: url,
            type: .subtitle,
            enforce: false
        )
    }

    var size: String? {
        guard let height, let width else { return nil }
        return "\(width)x\(height)"
    }

    var metadataProperties: [TextPairItem] {
        var properties: [TextPairItem] = []

        if let value = type {
            properties.append(.init(displayTitle: "Type", value: value.rawValue))
        }

        if let value = codec {
            properties.append(.init(displayTitle: "Codec", value: value))
        }

        if let value = codecTag {
            properties.append(.init(displayTitle: "Codec Tag", value: value))
        }

        if let value = language {
            properties.append(.init(displayTitle: "Language", value: value))
        }

        if let value = timeBase {
            properties.append(.init(displayTitle: "Time Base", value: value))
        }

        if let value = codecTimeBase {
            properties.append(.init(displayTitle: "Codec Time Base", value: value))
        }

        if let value = videoRange {
            properties.append(.init(displayTitle: "Video Range", value: value))
        }

        if let value = isInterlaced {
            properties.append(.init(displayTitle: "Interlaced", value: value.description))
        }

        if let value = isAVC {
            properties.append(.init(displayTitle: "AVC", value: value.description))
        }

        if let value = channelLayout {
            properties.append(.init(displayTitle: "Channel Layout", value: value))
        }

        if let value = bitRate {
            properties.append(.init(displayTitle: "Bitrate", value: value.description))
        }

        if let value = bitDepth {
            properties.append(.init(displayTitle: "Bit Depth", value: value.description))
        }

        if let value = refFrames {
            properties.append(.init(displayTitle: "Reference Frames", value: value.description))
        }

        if let value = packetLength {
            properties.append(.init(displayTitle: "Packet Length", value: value.description))
        }

        if let value = channels {
            properties.append(.init(displayTitle: "Channels", value: value.description))
        }

        if let value = sampleRate {
            properties.append(.init(displayTitle: "Sample Rate", value: value.description))
        }

        if let value = isDefault {
            properties.append(.init(displayTitle: "Default", value: value.description))
        }

        if let value = isForced {
            properties.append(.init(displayTitle: "Forced", value: value.description))
        }

        if let value = averageFrameRate {
            properties.append(.init(displayTitle: "Average Frame Rate", value: value.description))
        }

        if let value = realFrameRate {
            properties.append(.init(displayTitle: "Real Frame Rate", value: value.description))
        }

        if let value = profile {
            properties.append(.init(displayTitle: "Profile", value: value))
        }

        if let value = aspectRatio {
            properties.append(.init(displayTitle: "Aspect Ratio", value: value))
        }

        if let value = index {
            properties.append(.init(displayTitle: "Index", value: value.description))
        }

        if let value = score {
            properties.append(.init(displayTitle: "Score", value: value.description))
        }

        if let value = pixelFormat {
            properties.append(.init(displayTitle: "Pixel Format", value: value))
        }

        if let value = level {
            properties.append(.init(displayTitle: "Level", value: value.description))
        }

        if let value = isAnamorphic {
            properties.append(.init(displayTitle: "Anamorphic", value: value.description))
        }

        return properties
    }

    var colorProperties: [TextPairItem] {
        var properties: [TextPairItem] = []

        if let value = colorRange {
            properties.append(.init(displayTitle: "Range", value: value))
        }

        if let value = colorSpace {
            properties.append(.init(displayTitle: "Space", value: value))
        }

        if let value = colorTransfer {
            properties.append(.init(displayTitle: "Transfer", value: value))
        }

        if let value = colorPrimaries {
            properties.append(.init(displayTitle: "Primaries", value: value))
        }

        return properties
    }

    var deliveryProperties: [TextPairItem] {
        var properties: [TextPairItem] = []

        if let value = isExternal {
            properties.append(.init(displayTitle: "External", value: value.description))
        }

        if let value = deliveryMethod {
            properties.append(.init(displayTitle: "Delivery Method", value: value.rawValue))
        }

        if let value = deliveryUrl {
            properties.append(.init(displayTitle: "URL", value: value))
        }

        if let value = isExternalUrl {
            properties.append(.init(displayTitle: "External URL", value: value.description))
        }

        if let value = isTextSubtitleStream {
            properties.append(.init(displayTitle: "Text Subtitle", value: value.description))
        }

        if let value = path {
            properties.append(.init(displayTitle: "Path", value: value))
        }

        return properties
    }
}
