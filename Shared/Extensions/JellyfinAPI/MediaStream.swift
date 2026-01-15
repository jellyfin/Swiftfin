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

    /// Adjusts track indexes for VLC playback.
    /// Shows ALL tracks (embedded + external, regardless of deliveryURL).
    /// External tracks are always placed at the end after internal tracks.
    /// Indices are remapped to 0-based sequence for VLC.
    ///
    /// Returns: (adjusted streams with new indices, map of original index -> adjusted index)
    func adjustedIndexMap(for playMethod: PlayMethod, selectedAudioStreamIndex: Int) -> [Int: Int] {
        let internalTracks = self.filter { !($0.isExternal ?? false) }
        let externalTracks = self.filter { $0.isExternal == true }

        var orderedInternal: [MediaStream] = []
        let subtitleInternal = internalTracks.filter { $0.type == .subtitle }

        if playMethod == .transcode {
            // Only include the first video and selected audio track for transcode
            let videoInternal = internalTracks.filter { $0.type == .video }
            let audioInternal = internalTracks.filter { $0.type == .audio }

            if let firstVideo = videoInternal.first {
                orderedInternal.append(firstVideo)
            }
            if let selectedAudio = audioInternal.first(where: { $0.index == selectedAudioStreamIndex }) {
                orderedInternal.append(selectedAudio)
            }

            orderedInternal += subtitleInternal
        } else {
            let videoInternal = internalTracks.filter { $0.type == .video }
            let audioInternal = internalTracks.filter { $0.type == .audio }

            orderedInternal = videoInternal + audioInternal + subtitleInternal
        }

        // Remap indices for VLC (0-based sequence)
        var indexMap: [Int: Int] = [:]
        var newInternalTracks: [MediaStream] = []

        for (newIndex, var track) in orderedInternal.enumerated() {
            guard let oldIndex = track.index else { continue }

            track.index = newIndex
            indexMap[oldIndex] = newIndex
            newInternalTracks.append(track)
        }

        // Add ALL external tracks at the end
        let startingIndexForExternal = newInternalTracks.count

        for (offset, var track) in externalTracks.enumerated() {
            guard let oldIndex = track.index else { continue }

            let newIndex = startingIndexForExternal + offset
            track.index = newIndex
            indexMap[oldIndex] = newIndex
        }

        return indexMap
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
