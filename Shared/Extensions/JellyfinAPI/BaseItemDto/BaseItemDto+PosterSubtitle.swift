//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension BaseItemDto {

    func posterTitle(using field: PosterSubtitleField) -> String {
        // A parent title is useful only when the subtitle identifies its child.
        guard posterSubtitle(using: field) != nil else { return displayTitle }

        switch (type, field) {
        case (.season, .title):
            return parentTitle ?? displayTitle
        default:
            return displayTitle
        }
    }

    func posterSubtitle(using field: PosterSubtitleField) -> String? {
        let value = type == .person ? subtitle : posterSubtitleValue(for: field)
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }

    private func posterSubtitleValue(for field: PosterSubtitleField) -> String? {
        switch field {
        case .none:
            return nil
        case .year:
            if let year = productionYear, year > 0 {
                return year.description
            }
            return premiereDate?.formatted(.dateTime.year())
        case .runtime:
            return runtime?.formatted(.hourMinuteAbbreviated)
        case .officialRating:
            return officialRating
        case .communityRating:
            guard let rating = communityRating, rating.isFinite, (0 ... 10).contains(rating) else { return nil }
            return "★ \(rating.formatted(.number.precision(.fractionLength(0 ... 1))))"
        case .criticRating:
            guard let rating = criticRating, rating.isFinite, (0 ... 100).contains(rating) else { return nil }
            return L10n.posterCriticScore(rating.formatted(.number.precision(.fractionLength(0))))
        case .quality:
            return posterQualityLabel
        case .genre:
            return genres?.first
        case .studio:
            return studios?.first?.name
        case .episodeNumber:
            return seasonEpisodeLabel
        case .title:
            return name
        case .extraType:
            guard let extraType, extraType != .unknown else { return nil }
            return extraType.displayTitle
        }
    }

    private var posterQualityLabel: String? {
        let streams = (mediaStreams ?? []) + (mediaSources ?? []).flatMap { $0.mediaStreams ?? [] }
        let videos = streams.filter { $0.type == .video }
        guard let stream = videos.first(where: { $0.isDefault == true }) ?? videos.first else { return nil }

        var labels: [String] = []
        let width = stream.width ?? 0
        let height = stream.height ?? 0
        // Width also accounts for widescreen films whose black bars were cropped.
        if width >= 7680 || height >= 4320 {
            labels.append("8K")
        } else if width >= 3840 || height >= 2160 {
            labels.append("4K")
        } else if width >= 2560 || height >= 1440 {
            labels.append("1440p")
        } else if width >= 1920 || height >= 1080 {
            labels.append("1080p")
        } else if width >= 1280 || height >= 720 {
            labels.append("720p")
        } else if width > 0 || height > 0 {
            labels.append("SD")
        }

        if stream.videoRangeType?.isDolbyVision == true {
            labels.append(L10n.dolbyVision)
        } else if stream.videoRangeType?.isHDR == true || stream.videoRange == .hdr {
            labels.append(L10n.hdr)
        }
        return labels.isEmpty ? nil : labels.joined(separator: " ")
    }
}
