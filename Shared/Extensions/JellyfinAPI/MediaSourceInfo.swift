//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreTransferable
import JellyfinAPI

extension MediaSourceInfo: Displayable {

    var displayTitle: String {
        name ?? .emptyDash
    }
}

extension MediaSourceInfo {

    var supportedBitrates: [PlaybackBitrate] {
        let bitrates: [PlaybackBitrate] = if videoStreams?.isNotEmpty == true {
            PlaybackBitrate.videoBitrates
        } else if audioStreams?.isNotEmpty == true {
            PlaybackBitrate.audioBitrates
        } else {
            PlaybackBitrate.allCases
        }

        guard let bitrate else { return bitrates }

        return bitrates.filter {
            $0 == .max || $0.rawValue <= bitrate
        }
    }

    var audioStreams: [MediaStream]? {
        mediaStreams?.filter { $0.type == .audio }
    }

    var subtitleStreams: [MediaStream]? {
        mediaStreams?.filter { $0.type == .subtitle }
    }

    var videoStreams: [MediaStream]? {
        mediaStreams?.filter { $0.type == .video }
    }
}

extension MediaSourceInfo: @retroactive Transferable, TextTransferable {

    typealias Property = MediaStream.Property

    @ArrayBuilder<Property>
    var transferProperties: [Property] {
        if let value = path {
            (label: L10n.path, value: value)
        }

        if let value = container {
            (label: L10n.container, value: value)
        }

        if let value = size {
            (label: L10n.size, value: Int64(value).formatted(.byteCount(style: .binary)))
        }

        if let value = bitrate {
            (label: L10n.bitrate, value: value.formatted(.bitRate))
        }

        if let value = video3DFormat {
            (label: L10n.format3D, value: value.rawValue)
        }

        if let value = isoType {
            (label: L10n.isoType, value: value.rawValue)
        }

        if let value = timestamp {
            (label: L10n.timestamp, value: value.rawValue)
        }

        if let value = isRemote {
            (label: L10n.remote, value: value ? L10n.yes : L10n.no)
        }
    }

    public var transferTitle: String {
        displayTitle
    }

    public var transferBody: String {
        let properties = transferProperties
            .map { "\($0.label): \($0.value)" }
            .joined(separator: "\n")

        let source = [displayTitle, properties]
            .joined(separator: "\n\n")

        return ([source] + (mediaStreams ?? [])
            .map(\.transferBody))
            .joined(separator: "\n\n")
    }
}
