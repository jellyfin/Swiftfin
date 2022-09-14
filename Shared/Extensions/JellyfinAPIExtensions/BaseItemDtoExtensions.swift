//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import UIKit

extension BaseItemDto: Displayable {
    var displayName: String {
        name ?? .emptyDash
    }
}

extension BaseItemDto: Identifiable {}
extension BaseItemDto: LibraryParent {}

extension BaseItemDto {

    var episodeLocator: String? {
        guard let episodeNo = indexNumber else { return nil }
        return L10n.episodeNumber(episodeNo)
    }

    var seasonEpisodeLocator: String? {
        if let seasonNo = parentIndexNumber, let episodeNo = indexNumber {
            return L10n.seasonAndEpisode(String(seasonNo), String(episodeNo))
        }
        return nil
    }

    // MARK: Calculations

    func getItemRuntime() -> String? {
        let timeHMSFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.hour, .minute]
            return formatter
        }()

        guard let runTimeTicks = runTimeTicks,
              let text = timeHMSFormatter.string(from: Double(runTimeTicks / 10_000_000)) else { return nil }

        return text
    }

    var progress: String? {
        guard let playbackPositionTicks = userData?.playbackPositionTicks,
              let totalTicks = runTimeTicks,
              playbackPositionTicks != 0,
              totalTicks != 0 else { return nil }

        let remainingSeconds = (totalTicks - playbackPositionTicks) / 10_000_000

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated

        return formatter.string(from: .init(remainingSeconds))
    }

    func getLiveStartTimeString(formatter: DateFormatter) -> String {
        if let startDate = self.startDate {
            return formatter.string(from: startDate)
        }
        return " "
    }

    func getLiveEndTimeString(formatter: DateFormatter) -> String {
        if let endDate = self.endDate {
            return formatter.string(from: endDate)
        }
        return " "
    }

    func getLiveProgressPercentage() -> Double {
        if let startDate = self.startDate,
           let endDate = self.endDate
        {
            let start = startDate.timeIntervalSinceReferenceDate
            let end = endDate.timeIntervalSinceReferenceDate
            let now = Date().timeIntervalSinceReferenceDate
            let length = end - start
            let progress = now - start
            return progress / length
        }
        return 0
    }

    // MARK: ItemDetail

    struct ItemDetail {
        let title: String
        let content: String
    }

    func createInformationItems() -> [ItemDetail] {
        var informationItems: [ItemDetail] = []

        if let productionYear = productionYear {
            informationItems.append(ItemDetail(title: L10n.released, content: "\(productionYear)"))
        }

        if let rating = officialRating {
            informationItems.append(ItemDetail(title: L10n.rated, content: "\(rating)"))
        }

        if let runtime = getItemRuntime() {
            informationItems.append(ItemDetail(title: L10n.runtime, content: runtime))
        }

        return informationItems
    }

    func createMediaItems() -> [ItemDetail] {
        var mediaItems: [ItemDetail] = []

        if let mediaStreams = mediaStreams {
            let audioStreams = mediaStreams.filter { $0.type == .audio }
            let subtitleStreams = mediaStreams.filter { $0.type == .subtitle }

            if !audioStreams.isEmpty {
                let audioList = audioStreams.compactMap { "\($0.displayTitle ?? L10n.noTitle) (\($0.codec ?? L10n.noCodec))" }
                    .joined(separator: "\n")
                mediaItems.append(ItemDetail(title: L10n.audio, content: audioList))
            }

            if !subtitleStreams.isEmpty {
                let subtitleList = subtitleStreams.compactMap { "\($0.displayTitle ?? L10n.noTitle) (\($0.codec ?? L10n.noCodec))" }
                    .joined(separator: "\n")
                mediaItems.append(ItemDetail(title: L10n.subtitles, content: subtitleList))
            }
        }

        return mediaItems
    }

    var subtitleStreams: [MediaStream] {
        mediaStreams?.filter { $0.type == .subtitle } ?? []
    }

    var audioStreams: [MediaStream] {
        mediaStreams?.filter { $0.type == .audio } ?? []
    }

    // MARK: Missing and Unaired

    var missing: Bool {
        locationType == .virtual
    }

    var unaired: Bool {
        if let premierDate = premiereDate {
            return premierDate > Date()
        } else {
            return false
        }
    }

    var airDateLabel: String? {
        guard let premiereDateFormatted = premiereDateFormatted else { return nil }
        return L10n.airWithDate(premiereDateFormatted)
    }

    var premiereDateFormatted: String? {
        guard let premiereDate = premiereDate else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: premiereDate)
    }

    var premiereDateYear: String? {
        guard let premiereDate = premiereDate else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY"
        return dateFormatter.string(from: premiereDate)
    }

    // MARK: Chapter Images

    func getChapterImage(maxWidth: Int) -> [URL] {
        guard let chapters = chapters, !chapters.isEmpty else { return [] }

        var chapterImageURLs: [URL] = []

        for chapterIndex in 0 ..< chapters.count {
            let urlString = ImageAPI.getItemImageWithRequestBuilder(
                itemId: id ?? "",
                imageType: .chapter,
                maxWidth: maxWidth,
                imageIndex: chapterIndex
            ).URLString
            chapterImageURLs.append(URL(string: urlString)!)
        }

        return chapterImageURLs
    }

    // TODO: Don't use spoof objects as a placeholder or no results

    static var placeHolder: BaseItemDto {
        .init(
            name: "Placeholder",
            id: "1",
            overview: String(repeating: "a", count: 100),
            indexNumber: 20
        )
    }

    static var noResults: BaseItemDto {
        .init(name: L10n.noResults)
    }
}

extension BaseItemDtoImageBlurHashes {
    subscript(imageType: ImageType) -> [String: String]? {
        switch imageType {
        case .primary:
            return primary
        case .art:
            return art
        case .backdrop:
            return backdrop
        case .banner:
            return banner
        case .logo:
            return logo
        case .thumb:
            return thumb
        case .disc:
            return disc
        case .box:
            return box
        case .screenshot:
            return screenshot
        case .menu:
            return menu
        case .chapter:
            return chapter
        case .boxRear:
            return boxRear
        case .profile:
            return profile
        }
    }
}
