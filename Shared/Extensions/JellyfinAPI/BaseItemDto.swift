//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Algorithms
import Factory
import Foundation
import JellyfinAPI
import UIKit

extension BaseItemDto: Displayable {

    var displayTitle: String {
        name ?? .emptyDash
    }
}

extension BaseItemDto: LibraryParent {}

extension BaseItemDto {

    var episodeLocator: String? {
        guard let episodeNo = indexNumber else { return nil }
        return L10n.episodeNumber(episodeNo)
    }

    var runTimeSeconds: Int {
        let playbackPositionTicks = runTimeTicks ?? 0
        return Int(playbackPositionTicks / 10_000_000)
    }

    var seasonEpisodeLocator: String? {
        if let seasonNo = parentIndexNumber, let episodeNo = indexNumber {
            return L10n.seasonAndEpisode(String(seasonNo), String(episodeNo))
        }
        return nil
    }

    var startTimeSeconds: Int {
        let playbackPositionTicks = userData?.playbackPositionTicks ?? 0
        return Int(playbackPositionTicks / 10_000_000)
    }

    // MARK: Calculations

    // TODO: make computed var or function that takes allowed units
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

    var progressLabel: String? {
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

    var subtitleStreams: [MediaStream] {
        mediaStreams?.filter { $0.type == .subtitle } ?? []
    }

    var audioStreams: [MediaStream] {
        mediaStreams?.filter { $0.type == .audio } ?? []
    }

    var videoStreams: [MediaStream] {
        mediaStreams?.filter { $0.type == .video } ?? []
    }

    // MARK: Missing and Unaired

    var isMissing: Bool {
        locationType == .virtual
    }

    var isUnaired: Bool {
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

    var fullChapterInfo: [ChapterInfo.FullInfo] {
        guard let chapters else { return [] }

        let ranges: [Range<Int>] = []
            .appending(chapters.map(\.startTimeSeconds))
            .appending(runTimeSeconds + 1)
            .adjacentPairs()
            .map { $0 ..< $1 }

        return chapters
            .enumerated()
            .map { index, chapterInfo in

                let client = Container.userSession.callAsFunction().client
                let parameters = Paths.GetItemImageParameters(
                    maxWidth: 500,
                    quality: 90,
                    imageIndex: index
                )
                let request = Paths.getItemImage(
                    itemID: id ?? "",
                    imageType: ImageType.chapter.rawValue,
                    parameters: parameters
                )

                let imageURL = client.fullURL(with: request)

                let range = ranges.first(where: { $0.first == chapterInfo.startTimeSeconds }) ?? startTimeSeconds ..< startTimeSeconds + 1

                return ChapterInfo.FullInfo(
                    chapterInfo: chapterInfo,
                    imageSource: .init(url: imageURL),
                    secondsRange: range
                )
            }
    }

    // TODO: series-season-episode hierarchy for episodes
    // TODO: user hierarchy for downloads
    var downloadFolder: URL? {
        guard let type, let id else { return nil }

        let root = URL.downloads
//            .appendingPathComponent(userSession.user.id)

        switch type {
        case .movie, .episode:
            return root
                .appendingPathComponent(id)
//        case .episode:
//            guard let seasonID = seasonID,
//                  let seriesID = seriesID
//            else {
//                return nil
//            }
//            return root
//                .appendingPathComponent(seriesID)
//                .appendingPathComponent(seasonID)
//                .appendingPathComponent(id)
        default:
            return nil
        }
    }

    // TODO: Don't use spoof objects as a placeholder or no results

    static var placeHolder: BaseItemDto {
        .init(
            id: "1",
            name: "Placeholder",
            overview: String(repeating: "a", count: 100)
//            indexNumber: 20
        )
    }

    static func randomItem() -> BaseItemDto {
        .init(
            id: UUID().uuidString,
            name: "Lorem Ipsum",
            overview: "Lorem ipsum dolor sit amet"
        )
    }

    static var noResults: BaseItemDto {
        .init(name: L10n.noResults)
    }
}
