//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Algorithms
import AVKit
import Factory
import Foundation
import JellyfinAPI
import MediaPlayer
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

    var avMetadata: [AVMetadataItem] {
        let title: String
        var subtitle: String? = nil
        let description = overview

        if type == .episode,
           let seriesName = seriesName
        {
            title = seriesName
            subtitle = displayTitle
        } else {
            title = displayTitle
        }

        return [
            AVMetadataIdentifier.commonIdentifierTitle: title,
            .iTunesMetadataTrackSubTitle: subtitle,
            .commonIdentifierDescription: description,
        ]
            .compactMap { identifier, value in
                let item = AVMutableMetadataItem()
                item.identifier = identifier
                item.value = value as? NSCopying & NSObjectProtocol
                item.extendedLanguageTag = "und"

                return item.copy() as? AVMetadataItem
            }
    }

    func nowPlayableStaticMetadata(_ image: UIImage? = nil) -> NowPlayableStaticMetadata {

        let mediaType: MPNowPlayingInfoMediaType = {
            switch type {
            case .audio, .audioBook: .audio
            default: .video
            }
        }()

        // TODO: only fill artist, albumArtist, and albumTitle if audio type
        return .init(
            mediaType: mediaType,
            isLiveStream: isLiveStream,
            title: displayTitle,
            artist: nil,
            artwork: nil,
            albumArtist: nil,
            albumTitle: nil
        )
    }

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

    /// Differs from `isLive` to indicate an item
    /// would be streaming from a live source.
    var isLiveStream: Bool {
        channelType == .tv
    }

    // TODO: Change to Duration
    @available(*, deprecated, message: "Use `runtime` instead")
    var runTimeSeconds: TimeInterval {
        TimeInterval(runTimeTicks ?? 0) / 10_000_000
    }

    @available(*, deprecated, message: "Use `startDuration` instead")
    var startTimeSeconds: TimeInterval {
        TimeInterval(userData?.playbackPositionTicks ?? 0) / 10_000_000
    }

    var runtime: Duration? {
        guard let ticks = runTimeTicks else { return nil }
        return Duration.microseconds(ticks / 10)
    }

    var startSeconds: Duration? {
        guard let ticks = userData?.playbackPositionTicks else { return nil }
        return Duration.microseconds(ticks / 10)
    }

    var seasonEpisodeLabel: String? {
        guard let seasonNo = parentIndexNumber, let episodeNo = indexNumber else { return nil }
        return L10n.seasonAndEpisode(String(seasonNo), String(episodeNo))
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

    // TODO: move to whatever listener for chapters
    var fullChapterInfo: [ChapterInfo.FullInfo] {
        guard let chapters else { return [] }

        let afterRuntime = (runtime ?? .zero) + .seconds(1)

        let ranges: [Range<Duration>] = chapters
            .map { $0.startSeconds ?? .zero }
            .appending(afterRuntime)
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
                    secondsRange: zip.1,
                    runtime: runtime ?? .zero
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

    /// Returns `originalTitle` if it is not the same as `displayTitle`
    var alternateTitle: String? {
        originalTitle != displayTitle ? originalTitle : nil
    }

    /// Can this `BaseItemDto` be played
    var presentPlayButton: Bool {
        switch type {
        case .audio, .audioBook, .book, .channel, .channelFolderItem, .episode,
             .movie, .liveTvChannel, .liveTvProgram, .musicAlbum, .musicArtist, .musicVideo, .playlist,
             .program, .recording, .season, .series, .trailer, .tvChannel, .tvProgram, .video:
            return true
        default:
            return false
        }
    }

    /// Can this `BaseItemDto` be mark as played
    var canBePlayed: Bool {
        switch type {
        case .audio, .audioBook, .book, .boxSet, .channel, .channelFolderItem, .collectionFolder, .episode, .manualPlaylistsFolder,
             .movie, .liveTvChannel, .liveTvProgram, .musicAlbum, .musicArtist, .musicVideo, .playlist, .playlistsFolder,
             .program, .recording, .season, .series, .trailer, .tvChannel, .tvProgram, .video:
            return true
        default:
            return false
        }
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

    /// Does this `BaseItemDto` have `Genres`, `People`, `Studios`, or `Tags`
    var hasComponents: Bool {
        switch type {
        case .audio, .audioBook, .book, .boxSet, .channelFolderItem, .collectionFolder, .episode, .manualPlaylistsFolder, .movie,
             .liveTvProgram, .musicAlbum, .musicArtist, .musicVideo, .playlist, .playlistsFolder, .program, .recording, .season,
             .series, .trailer, .tvProgram, .video:
            return true
        default:
            return false
        }
    }
}
