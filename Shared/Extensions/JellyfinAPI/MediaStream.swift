//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import VLCUI

extension MediaStream {

    typealias Property = (label: String, value: String)

    static var none: MediaStream = .init(displayTitle: L10n.none, index: -1)

    var asVLCPlaybackChild: VLCVideoPlayer.PlaybackChild? {
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

    @ArrayBuilder<Property>
    var metadataProperties: [Property] {
        if let value = type {
            (label: "Type", value: value.rawValue)
        }

        if let value = codec {
            (label: "Codec", value: value)
        }

        if let value = codecTag {
            (label: "Codec Tag", value: value)
        }

        if let value = language {
            (label: "Language", value: value)
        }

        if let value = timeBase {
            (label: "Time Base", value: value)
        }

        if let value = codecTimeBase {
            (label: "Codec Time Base", value: value)
        }

        if let value = videoRange {
            (label: "Video Range", value: value.rawValue)
        }

        if let value = isInterlaced {
            (label: "Interlaced", value: value.description)
        }

        if let value = isAVC {
            (label: "AVC", value: value.description)
        }

        if let value = channelLayout {
            (label: "Channel Layout", value: value)
        }

        if let value = bitRate {
            (label: "Bitrate", value: value.description)
        }

        if let value = bitDepth {
            (label: "Bit Depth", value: value.description)
        }

        if let value = refFrames {
            (label: "Reference Frames", value: value.description)
        }

        if let value = packetLength {
            (label: "Packet Length", value: value.description)
        }

        if let value = channels {
            (label: "Channels", value: value.description)
        }

        if let value = sampleRate {
            (label: "Sample Rate", value: value.description)
        }

        if let value = isDefault {
            (label: "Default", value: value.description)
        }

        if let value = isForced {
            (label: "Forced", value: value.description)
        }

        if let value = averageFrameRate {
            (label: "Average Frame Rate", value: value.description)
        }

        if let value = realFrameRate {
            (label: "Real Frame Rate", value: value.description)
        }

        if let value = profile {
            (label: "Profile", value: value)
        }

        if let value = aspectRatio {
            (label: "Aspect Ratio", value: value)
        }

        if let value = index {
            (label: "Index", value: value.description)
        }

        if let value = score {
            (label: "Score", value: value.description)
        }

        if let value = pixelFormat {
            (label: "Pixel Format", value: value)
        }

        if let value = level {
            (label: "Level", value: value.description)
        }

        if let value = isAnamorphic {
            (label: "Anamorphic", value: value.description)
        }
    }

    @ArrayBuilder<Property>
    var colorProperties: [Property] {
        if let value = colorRange {
            (label: "Range", value: value)
        }

        if let value = colorSpace {
            (label: "Space", value: value)
        }

        if let value = colorTransfer {
            (label: "Transfer", value: value)
        }

        if let value = colorPrimaries {
            (label: "Primaries", value: value)
        }
    }

    @ArrayBuilder<Property>
    var deliveryProperties: [Property] {
        if let value = isExternal {
            (label: "External", value: value.description)
        }

        if let value = deliveryMethod {
            (label: "Delivery Method", value: value.rawValue)
        }

        if let value = deliveryURL {
            (label: "URL", value: value)
        }

        if let value = deliveryURL {
            (label: "External URL", value: value.description)
        }

        if let value = isTextSubtitleStream {
            (label: "Text Subtitle", value: value.description)
        }

        if let value = path {
            (label: "Path", value: value)
        }
    }
}

extension [MediaStream] {

    /// Maps Jellyfin stream indexes to VLC track indexes.
    ///
    /// - **Transcode**: HLS has 1 video + 1 audio; subtitles are playback children starting at index 2.
    /// - **DirectPlay**: Jellyfin indexes externals first, then internals. Subtract external count
    ///   to get VLC container position. External subtitle indexes are resolved at runtime via
    ///   `resolveExternalSubtitleIndexes` since the server may hide container tracks (e.g. PGS
    ///   filtered by "Disable embedded subtitles") that VLC still sees.
    func adjustedIndexMap(
        for playMethod: PlayMethod,
        selectedAudioStreamIndex: Int
    ) -> [Int: Int] {
        var indexMap: [Int: Int] = [:]

        if playMethod == .transcode {
            var containerTracks: [MediaStream] = []

            let videoTracks = self.filter { $0.type == .video && !($0.isExternal ?? false) }
            let audioTracks = self.filter { $0.type == .audio && !($0.isExternal ?? false) }

            if let firstVideo = videoTracks.first {
                containerTracks.append(firstVideo)
            }
            if let selectedAudio = audioTracks.first(where: { $0.index == selectedAudioStreamIndex }) {
                containerTracks.append(selectedAudio)
            }

            for (newIndex, track) in containerTracks.enumerated() {
                guard let oldIndex = track.index else { continue }
                indexMap[oldIndex] = newIndex
            }

            let externalSubtitles = self.filter { $0.type == .subtitle && $0.deliveryURL != nil }
            let externalStartIndex = containerTracks.count

            for (offset, track) in externalSubtitles.enumerated() {
                guard let oldIndex = track.index else { continue }
                indexMap[oldIndex] = externalStartIndex + offset
            }
        } else {
            let externalCount = self.count(where: { $0.isExternal == true })
            let internalTracks = self.filter { !($0.isExternal ?? false) }

            for track in internalTracks {
                guard let oldIndex = track.index else { continue }
                indexMap[oldIndex] = oldIndex - externalCount
            }

            /// External subtitle indexes resolved dynamically in `resolveExternalSubtitleIndexes`
        }

        return indexMap
    }

    /// Resolves external subtitle VLC indexes using VLC's actual track list after media loads.
    /// Playback children always get the highest indexes (appended after container tracks).
    /// Takes the last N unmapped VLC subtitle indexes where N = external subtitle count.
    static func resolveExternalSubtitleIndexes(
        vlcSubtitleTracks: [(index: Int, title: String)],
        currentIndexMap: [Int: Int],
        externalSubtitleStreams: [MediaStream]
    ) -> [Int: Int] {
        guard !externalSubtitleStreams.isEmpty else { return currentIndexMap }

        var updatedMap = currentIndexMap

        let mappedVLCIndexes = Set(currentIndexMap.values)
        let unmappedVLCIndexes = vlcSubtitleTracks
            .map(\.index)
            .filter { $0 >= 0 && !mappedVLCIndexes.contains($0) }
            .sorted()

        let externalVLCIndexes = [Int](unmappedVLCIndexes.suffix(externalSubtitleStreams.count))

        for (offset, stream) in externalSubtitleStreams.enumerated() {
            guard let jellyfinIndex = stream.index else { continue }
            if offset < externalVLCIndexes.count {
                updatedMap[jellyfinIndex] = externalVLCIndexes[offset]
            }
        }

        return updatedMap
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
