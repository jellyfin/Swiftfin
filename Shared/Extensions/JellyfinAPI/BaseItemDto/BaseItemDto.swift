//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Algorithms
import AVKit
import Factory
import Foundation
import JellyfinAPI
import MediaPlayer
import Nuke
import SwiftUI

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

        let title: String = {
            if type == .episode,
               let seriesName = seriesName
            {
                return seriesName
            } else {
                return displayTitle
            }
        }()

        let albumArtist: String? = {
            switch type {
            case .audio:
                return artists?.joined(separator: ", ")
            default:
                return nil
            }
        }()

        let albumTitle: String? = {
            switch type {
            case .audio:
                return album
            default:
                return nil
            }
        }()

        // TODO: only fill artist, albumArtist, and albumTitle if audio type
        return .init(
            mediaType: mediaType,
            isLiveStream: isLiveStream,
            title: title,
            artist: subtitle,
            artwork: image.map { image in MPMediaItemArtwork(boundsSize: image.size) { _ in image }},
            albumArtist: albumArtist,
            albumTitle: albumTitle
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

    /// Whether the item has independent playable content, similar
    /// to if an item can provide its own media sources.
    ///
    /// ie: A movie and an episode can be directly played,
    ///     but a series is not as its episodes are playable.
    var isPlayable: Bool {
        guard !isMissing else { return false }

        return switch type {
        case .series:
            false
        default:
            true
        }
    }

    /// The primary image handler for building the
    /// image used in the now playing system.
    @MainActor
    func getNowPlayingImage() async -> UIImage? {
        let imageSources = thumbImageSources()

        guard let firstImage = await ImagePipeline.Swiftfin.other.loadFirstImage(from: imageSources) else {
            let failedSystemContentView = SystemImageContentView(
                systemName: systemImage
            )
            .posterStyle(preferredPosterDisplayType)
            .frame(width: 400)

            return ImageRenderer(content: failedSystemContentView).uiImage
        }

        let image = Image(uiImage: firstImage)
            .resizable()
        let transformedImage = ZStack {
            Rectangle()
                .fill(Color.secondarySystemFill)

            transform(image: image)
        }
        .posterAspectRatio(preferredPosterDisplayType, contentMode: .fit)
        .frame(width: 400)

        return ImageRenderer(content: transformedImage).uiImage
    }

    func getPlaybackItemProvider(
        userSession: UserSession
    ) -> MediaPlayerItemProvider {
        switch type {
        case .program:
            MediaPlayerItemProvider(item: self) { program in
                guard let channel = try? await self.getChannel(
                    for: program,
                    userSession: userSession
                ),
                    let mediaSource = channel.mediaSources?.first
                else {
                    throw ErrorMessage(L10n.unknownError)
                }
                return try await MediaPlayerItem.build(for: program, mediaSource: mediaSource)
            }
        default:
            MediaPlayerItemProvider(item: self) { item in
                guard let mediaSource = item.mediaSources?.first else {
                    throw ErrorMessage(L10n.unknownError)
                }
                return try await MediaPlayerItem.build(for: item, mediaSource: mediaSource)
            }
        }
    }

    func getChannel(
        for program: BaseItemDto,
        userSession: UserSession
    ) async throws -> BaseItemDto? {
        guard type == .program else { return nil }

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.ids = [program.channelID ?? ""]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items?.first
    }

    var runtime: Duration? {
        guard let ticks = runTimeTicks else { return nil }
        return Duration.ticks(ticks)
    }

    var startSeconds: Duration? {
        guard let ticks = userData?.playbackPositionTicks else { return nil }
        return Duration.ticks(ticks)
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

    var fullChapterInfo: [ChapterInfo.FullInfo]? {

        guard let chapters = chapters?
            .sorted(using: \.startPositionTicks)
            .compacted(using: \.startPositionTicks) else { return nil }

        guard let userSession = Container.shared.currentUserSession() else { return nil }

        return chapters
            .enumerated()
            .map { i, chapter in

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

                let imageURL = userSession
                    .client
                    .fullURL(with: request)

                return .init(
                    chapterInfo: chapter,
                    imageSource: .init(url: imageURL)
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

    func getFullItem(userSession: UserSession) async throws -> BaseItemDto {
        guard let id else {
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Paths.getItem(itemID: id, userID: userSession.user.id)
        let response = try await userSession.client.send(request)

        // A check against `id` would typically be done, but a plugin
        // may have provided `self` or the response item and may not
        // be invariant over `id`.

        return response.value
    }
}
