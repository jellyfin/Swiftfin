//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreTransferable
import Foundation
import JellyfinAPI

extension MediaStream {

    typealias Property = (label: String, value: String)

    static var none: MediaStream = .init(displayTitle: L10n.none, index: -1)

    func url(with client: JellyfinClient) -> URL? {
        guard let deliveryURL else { return nil }

        let deliveryPath = deliveryURL.removingFirst(if: client.configuration.url.absoluteString.last == "/")
        return client.url(path: deliveryPath)
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

    @ArrayBuilder<Property>
    var metadataProperties: [Property] {
        if let value = type {
            (label: L10n.type, value: value.rawValue)
        }

        if let value = codec {
            (label: L10n.codec, value: value)
        }

        if let value = codecTag {
            (label: L10n.codecTag, value: value)
        }

        if let value = language {
            (label: L10n.language, value: value)
        }

        if let value = timeBase {
            (label: L10n.timeBase, value: value)
        }

        if let value = codecTimeBase {
            (label: L10n.codecTimeBase, value: value)
        }

        if let value = videoRange {
            (label: L10n.videoRange, value: value.rawValue)
        }

        if let value = isInterlaced {
            (label: L10n.interlaced, value: value ? L10n.yes : L10n.no)
        }

        if let value = isAVC {
            (label: L10n.avc, value: value ? L10n.yes : L10n.no)
        }

        if let value = channelLayout {
            (label: L10n.channelLayout, value: value)
        }

        if let value = bitRate {
            (label: L10n.bitrate, value: value.description)
        }

        if let value = bitDepth {
            (label: L10n.bitDepth, value: value.description)
        }

        if let value = refFrames {
            (label: L10n.referenceFrames, value: value.description)
        }

        if let value = packetLength {
            (label: L10n.packetLength, value: value.description)
        }

        if let value = channels {
            (label: L10n.channels, value: value.description)
        }

        if let value = sampleRate {
            (label: L10n.sampleRate, value: value.description)
        }

        if let value = isDefault {
            (label: L10n.default, value: value ? L10n.yes : L10n.no)
        }

        if let value = isForced {
            (label: L10n.forced, value: value ? L10n.yes : L10n.no)
        }

        if let value = averageFrameRate {
            (label: L10n.averageFrameRate, value: value.description)
        }

        if let value = realFrameRate {
            (label: L10n.realFrameRate, value: value.description)
        }

        if let value = profile {
            (label: L10n.profile, value: value)
        }

        if let value = aspectRatio {
            (label: L10n.aspectRatio, value: value)
        }

        if let value = index {
            (label: L10n.index, value: value.description)
        }

        if let value = score {
            (label: L10n.score, value: value.description)
        }

        if let value = pixelFormat {
            (label: L10n.pixelFormat, value: value)
        }

        if let value = level {
            (label: L10n.level, value: value.description)
        }

        if let value = isAnamorphic {
            (label: L10n.anamorphic, value: value ? L10n.yes : L10n.no)
        }
    }

    @ArrayBuilder<Property>
    var colorProperties: [Property] {
        if let value = colorRange {
            (label: L10n.range, value: value)
        }

        if let value = colorSpace {
            (label: L10n.colorSpace, value: value)
        }

        if let value = colorTransfer {
            (label: L10n.transfer, value: value)
        }

        if let value = colorPrimaries {
            (label: L10n.primaries, value: value)
        }
    }

    @ArrayBuilder<Property>
    var deliveryProperties: [Property] {
        if let value = isExternal {
            (label: L10n.external, value: value ? L10n.yes : L10n.no)
        }

        if let value = deliveryMethod {
            (label: L10n.deliveryMethod, value: value.rawValue)
        }

        if let value = deliveryURL {
            (label: L10n.url, value: value)
        }

        if let value = deliveryURL {
            (label: L10n.externalURL, value: value.description)
        }

        if let value = isTextSubtitleStream {
            (label: L10n.textSubtitle, value: value ? L10n.yes : L10n.no)
        }

        if let value = path {
            (label: L10n.path, value: value)
        }
    }
}

extension MediaStream: @retroactive Transferable, TextTransferable {

    @ArrayBuilder<Property>
    private var sharedTransferProperties: [Property] {
        if let value = displayTitle {
            (label: L10n.title, value: value)
        }

        if let value = language {
            (label: L10n.language, value: value)
        }

        if let value = codec {
            (label: L10n.codec, value: value.uppercased())
        }

        if let value = isAVC {
            (label: L10n.avc, value: value ? L10n.yes : L10n.no)
        }

        if let value = profile {
            (label: L10n.profile, value: value)
        }
    }

    @ArrayBuilder<Property>
    private var resolutionTransferProperties: [Property] {
        if let width, let height, width > 0, height > 0 {
            (label: L10n.resolution, value: width.description.multiply(by: height.description))
        }
    }

    @ArrayBuilder<Property>
    private var flagTransferProperties: [Property] {
        if let value = isDefault {
            (label: L10n.default, value: value ? L10n.yes : L10n.no)
        }

        if let value = isForced {
            (label: L10n.forced, value: value ? L10n.yes : L10n.no)
        }

        if let value = isExternal {
            (label: L10n.external, value: value ? L10n.yes : L10n.no)
        }
    }

    @ArrayBuilder<Property>
    private var videoTransferProperties: [Property] {
        if let value = level {
            (label: L10n.level, value: value.formatted())
        }

        if let value = aspectRatio {
            (label: L10n.aspectRatio, value: value)
        }

        if let value = isAnamorphic {
            (label: L10n.anamorphic, value: value ? L10n.yes : L10n.no)
        }

        if let value = isInterlaced {
            (label: L10n.interlaced, value: value ? L10n.yes : L10n.no)
        }

        if let value = realFrameRate ?? averageFrameRate {
            (label: L10n.framerate, value: value.description)
        }

        if let value = bitRate {
            (label: L10n.bitrate, value: value.formatted(.bitRate))
        }

        if let value = bitDepth {
            (label: L10n.bitDepth, value: "\(value) bit")
        }

        if let value = videoRange {
            (label: L10n.videoRange, value: value.rawValue)
        }

        if let value = videoRangeType {
            (label: L10n.videoRangeType, value: value.rawValue)
        }

        if let value = pixelFormat {
            (label: L10n.pixelFormat, value: value)
        }

        if let value = refFrames {
            (label: L10n.referenceFrames, value: value.description)
        }

        if let value = nalLengthSize {
            (label: L10n.nal, value: value)
        }
    }

    @ArrayBuilder<Property>
    private var audioTransferProperties: [Property] {
        if let value = channelLayout {
            (label: L10n.layout, value: value)
        }

        if let value = channels {
            (label: L10n.channels, value: "\(value) ch")
        }

        if let value = bitRate {
            (label: L10n.bitrate, value: value.formatted(.bitRate))
        }

        if let value = sampleRate {
            (label: L10n.sampleRate, value: "\(value) Hz")
        }
    }

    @ArrayBuilder<Property>
    var transferProperties: [Property] {

        sharedTransferProperties

        switch type {
        case .video:
            resolutionTransferProperties
            videoTransferProperties
        case .audio:
            audioTransferProperties
            flagTransferProperties
        case .subtitle:
            resolutionTransferProperties
            flagTransferProperties
        default:
            []
        }
    }

    public var transferTitle: String {
        displayTitle ?? type?.displayTitle ?? .emptyDash
    }

    public var transferBody: String {
        let properties = transferProperties
            .map {
                "\($0.label): \($0.value)"
            }
            .joined(separator: "\n")

        return [type?.displayTitle ?? L10n.media, properties]
            .joined(separator: "\n\n")
    }
}

extension [MediaStream] {

    /// Text-based external subtitles loaded as sidecar files. Image-based subtitles are excluded because the player silently drops them.
    var sidecarSubtitles: [MediaStream] {
        filter { $0.deliveryMethod == .external && $0.deliveryURL != nil && $0.isTextSubtitleStream == true }
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

    var hasHDRVideo: Bool {
        contains { $0.videoRangeType?.isHDR == true }
    }

    var hasDolbyVision: Bool {
        contains { $0.videoRangeType?.isDolbyVision == true }
    }

    var hasSubtitles: Bool {
        contains { $0.type == .subtitle }
    }
}
