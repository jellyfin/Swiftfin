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

    /// Adjusts track indexes for a full set of media streams.
    /// For non-transcode stream types:
    ///   Internal tracks (non-external) are ordered as: Video, Audio, Subtitles, then any others.
    ///   Their relative order within each group is preserved and indexes start at 0.
    /// For transcode stream type:
    ///   Only the first internal video track and the first internal audio track are included, in that order.
    /// In both cases, external tracks are appended in their original order with indexes continuing after internal tracks.
    func adjustedTrackIndexes(for streamType: StreamType, selectedAudioStreamIndex: Int) -> [MediaStream] {
        let internalTracks = self.filter { !($0.isExternal ?? false) }
        let externalTracks = self.filter { $0.isExternal ?? false }

        var orderedInternal: [MediaStream] = []

        let subtitleInternal = internalTracks.filter { $0.type == .subtitle }

        // TODO: Do we need this for other media types? I think movies/shows we only care about video, audio, and subtitles.
        let otherInternal = internalTracks.filter { $0.type != .video && $0.type != .audio && $0.type != .subtitle }

        if streamType == .transcode {
            // Only include the first video and first audio track for transcode.
            let videoInternal = internalTracks.filter { $0.type == .video }
            let audioInternal = internalTracks.filter { $0.type == .audio }

            if let firstVideo = videoInternal.first {
                orderedInternal.append(firstVideo)
            }
            if let selectedAudio = audioInternal.first(where: { $0.index == selectedAudioStreamIndex }) {
                orderedInternal.append(selectedAudio)
            }

            orderedInternal += subtitleInternal
            orderedInternal += otherInternal
        } else {
            let videoInternal = internalTracks.filter { $0.type == .video }
            let audioInternal = internalTracks.filter { $0.type == .audio }

            orderedInternal = videoInternal + audioInternal + subtitleInternal + otherInternal
        }

        var newInternalTracks: [MediaStream] = []
        for (index, var track) in orderedInternal.enumerated() {
            track.index = index
            newInternalTracks.append(track)
        }

        var newExternalTracks: [MediaStream] = []
        let startingIndexForExternal = newInternalTracks.count
        for (offset, var track) in externalTracks.enumerated() {
            track.index = startingIndexForExternal + offset
            newExternalTracks.append(track)
        }

        return newInternalTracks + newExternalTracks
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
        contains { VideoRangeType(from: $0.videoRangeType).isHDR }
    }

    var hasDolbyVision: Bool {
        contains { VideoRangeType(from: $0.videoRangeType).isDolbyVision }
    }

    var hasSubtitles: Bool {
        contains { $0.type == .subtitle }
    }
}
