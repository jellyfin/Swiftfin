//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Algorithms
import Factory
import Foundation
import JellyfinAPI
import Logging
import UIKit

// TODO: clean up

extension BaseItemDto {

    init(person: BaseItemPerson) {
        self.init(
            id: person.id,
            name: person.name,
            type: .person
        )
    }
}

extension BaseItemDto: Displayable {

    var displayTitle: String {
        name ?? L10n.unknown
    }
}

extension BaseItemDto: LibraryIdentifiable {

    var unwrappedIDHashOrZero: Int {
        id?.hashValue ?? 0
    }
}

extension BaseItemDto {

    var birthday: Date? {
        guard type == .person else { return nil }
        return premiereDate
    }

    var birthplace: String? {
        guard type == .person else { return nil }
        return productionLocations?.first
    }

    var deathday: Date? {
        guard type == .person else { return nil }
        return endDate
    }

    var episodeLocator: String? {
        guard let episodeNo = indexNumber else { return nil }
        return L10n.episodeNumber(episodeNo)
    }

    var itemGenres: [ItemGenre]? {
        guard let genres else { return nil }
        return genres.map(ItemGenre.init)
    }

    var runTimeSeconds: Int {
        let playbackPositionTicks = runTimeTicks ?? 0
        return Int(playbackPositionTicks / 10_000_000)
    }

    var seasonEpisodeLabel: String? {
        guard let seasonNo = parentIndexNumber, let episodeNo = indexNumber else { return nil }
        return L10n.seasonAndEpisode(String(seasonNo), String(episodeNo))
    }

    var startTimeSeconds: Int {
        let playbackPositionTicks = userData?.playbackPositionTicks ?? 0
        return Int(playbackPositionTicks / 10_000_000)
    }

    // MARK: Calculations

    var runTimeLabel: String? {
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

    var programDuration: TimeInterval? {
        guard let startDate, let endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }

    var programProgress: Double? {
        guard let startDate, let endDate else { return nil }

        let length = endDate.timeIntervalSince(startDate)
        let progress = Date.now.timeIntervalSince(startDate)

        return progress / length
    }

    func programProgress(relativeTo other: Date) -> Double? {
        guard let startDate, let endDate else { return nil }

        let length = endDate.timeIntervalSince(startDate)
        let progress = other.timeIntervalSince(startDate)

        return progress / length
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
        guard let premiereDateFormatted = premiereDateLabel else { return nil }
        return L10n.airWithDate(premiereDateFormatted)
    }

    var premiereDateLabel: String? {
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

    var hasExternalLinks: Bool {
        guard let externalURLs else { return false }
        return externalURLs.isNotEmpty
    }

    var hasRatings: Bool {
        [
            criticRating,
            communityRating,
        ].contains { $0 != nil }
    }

    // MARK: Chapter Images

    var fullChapterInfo: [ChapterInfo.FullInfo] {
        guard let chapters else { return [] }

        let ranges: [Range<Int>] = chapters
            .map(\.startTimeSeconds)
            .appending(runTimeSeconds + 1)
            .adjacentPairs()
            .map { $0 ..< $1 }

        return zip(chapters, ranges)
            .enumerated()
            .map { i, zip in

                let parameters = Paths.GetItemImageParameters(
                    maxWidth: 500,
                    quality: 90,
                    imageIndex: i
                )

                let request = Paths.getItemImage(
                    itemID: id ?? "",
                    imageType: ImageType.chapter.rawValue,
                    parameters: parameters
                )

                let imageURL = Container.shared.currentUserSession()!
                    .client
                    .fullURL(with: request)

                return .init(
                    chapterInfo: zip.0,
                    imageSource: .init(url: imageURL),
                    secondsRange: zip.1
                )
            }
    }

    // TODO: series-season-episode hierarchy for episodes
    // TODO: user hierarchy for downloads
    var downloadFolder: URL? {
        // Enhanced logging for debugging download folder issues
        let logger = Logging.Logger.swiftfin()

        logger.debug("Computing download folder for item: \(displayTitle)")
        logger.debug("Item ID: \(id ?? "nil")")
        logger.debug("Item type: \(type?.rawValue ?? "nil")")

        guard let id = id else {
            logger.error("Download folder calculation failed: Item ID is nil for '\(displayTitle)'")
            return nil
        }

        guard let type = type else {
            logger.error("Download folder calculation failed: Item type is nil for '\(displayTitle)' (ID: \(id))")

            // Try to infer type from other properties if possible
            if let mediaSources = mediaSources, !mediaSources.isEmpty {
                logger.info("Attempting to infer type from media sources for item '\(displayTitle)'")
                let folder = URL.downloads.appendingPathComponent(id)
                logger.debug("Inferred download folder: \(folder.path)")
                return folder
            }

            return nil
        }

        let root = URL.downloads
//            .appendingPathComponent(userSession.user.id)

        switch type {
        case .movie, .video, .musicVideo, .trailer:
            let folder = root.appendingPathComponent(id)
            logger.debug("Download folder calculated: \(folder.path)")
            return folder
        case .episode:
            // Organize episodes within series folders: series_folder/episode_X/
            if let seriesID = seriesID, let seasonID = seasonID {
                // Full hierarchy: series/season/episode
                let folder = root
                    .appendingPathComponent(seriesID)
                    .appendingPathComponent(seasonID)
                    .appendingPathComponent(id)
                logger.debug("Download folder calculated for episode (full hierarchy): \(folder.path)")
                return folder
            } else if let seriesID = seriesID {
                // Series/episode hierarchy (no season)
                let folder = root
                    .appendingPathComponent(seriesID)
                    .appendingPathComponent(id)
                logger.debug("Download folder calculated for episode (series hierarchy): \(folder.path)")
                return folder
            } else {
                // Fallback to episode ID only
                let folder = root.appendingPathComponent(id)
                logger.debug("Download folder calculated for episode (fallback): \(folder.path)")
                return folder
            }
        case .series:
            // Series get their own folder for organizing episodes
            let folder = root.appendingPathComponent(id)
            logger.debug("Download folder calculated for series: \(folder.path)")
            return folder
        case .season:
            // Seasons are organized within series
            if let seriesID = seriesID {
                let folder = root
                    .appendingPathComponent(seriesID)
                    .appendingPathComponent(id)
                logger.debug("Download folder calculated for season: \(folder.path)")
                return folder
            } else {
                let folder = root.appendingPathComponent(id)
                logger.debug("Download folder calculated for season (fallback): \(folder.path)")
                return folder
            }
        case .audio:
            // Add support for audio files
            let folder = root.appendingPathComponent(id)
            logger.debug("Download folder calculated for audio: \(folder.path)")
            return folder
        default:
            logger.warning("Download folder calculation failed: Unsupported item type '\(type.rawValue)' for '\(displayTitle)' (ID: \(id))")

            // For unknown types, check if the item has downloadable media sources
            if let mediaSources = mediaSources, !mediaSources.isEmpty {
                logger.info("Item has media sources, allowing download despite unsupported type")
                let folder = root.appendingPathComponent(id)
                logger.debug("Fallback download folder: \(folder.path)")
                return folder
            }

            return nil
        }
    }

    /// Returns `originalTitle` if it is not the same as `displayTitle`
    var alternateTitle: String? {
        originalTitle != displayTitle ? originalTitle : nil
    }

    var playButtonLabel: String {

        if isUnaired {
            return L10n.unaired
        }

        if isMissing {
            return L10n.missing
        }

        if let progressLabel {
            return progressLabel
        }

        return L10n.play
    }

    var parentTitle: String? {
        switch type {
        case .audio:
            album
        case .episode:
            seriesName
        default:
            nil
        }
    }
}
