//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Get
import JellyfinAPI
import SwiftUI

final class ItemContentGroupProvider: ViewModel, ContentGroupProvider {

    @Published
    private(set) var item: BaseItemDto
    @Published
    private(set) var localTrailers: [BaseItemDto] = []
    @Published
    private(set) var playButtonItem: BaseItemDto?
    @Published
    private(set) var randomBackdropItem: BaseItemDto?
    @Published
    var selectedMediaSource: MediaSourceInfo?

    let id: String

    var displayTitle: String {
        item.displayTitle
    }

    init(item: BaseItemDto) {
        self.id = item.id ?? "Unknown"
        self.item = item
        super.init()
    }

    init(id: String) {
        self.id = id
        self.item = .init(id: id)
        super.init()
    }

    func makeGroups(environment: Empty) async throws -> [any ContentGroup] {
        let fullItem = try await item.getFullItem(userSession: requireUserSession(), sendNotification: true)
        let newPlayButtonItem = try await playButtonItem(for: fullItem)
        let newLocalTrailers = try? await localTrailers(for: fullItem)
        let newRandomBackdropItem = try? await randomBackdropItem(for: fullItem)

        item = fullItem
        localTrailers = newLocalTrailers ?? []
        randomBackdropItem = newRandomBackdropItem
        setPlayButtonItem(newPlayButtonItem)

        return try await _makeGroups(
            item: fullItem,
            itemID: id
        )
    }

    @ContentGroupBuilder
    private func _makeGroups(item: BaseItemDto, itemID: String) async throws -> [any ContentGroup] {

        if let birthday = item.birthday?.formatted(date: .long, time: .omitted) {
            LabeledContentGroup(
                L10n.born,
                value: birthday
            )
        }

        if let deathday = item.deathday?.formatted(date: .long, time: .omitted) {
            LabeledContentGroup(
                L10n.died,
                value: deathday
            )
        }

        if let birthplace = item.birthplace {
            LabeledContentGroup(
                L10n.birthplace,
                value: birthplace
            )
        }

        switch item.type {
        case .season, .series:
            SeriesEpisodeContentGroup(
                parent: item,
                playButtonItem: playButtonItem
            )
        default:
            []
        }

        if let genres = item.itemGenres, genres.isNotEmpty {
            PillGroup(
                displayTitle: L10n.genres,
                id: "genres",
                elements: genres
            ) { router, element in
                router.route(
                    to: .contentGroup(
                        provider: ItemTypeContentGroupProvider(
                            itemTypes: [
                                BaseItemKind.movie,
                                .series,
                                .boxSet,
                                .episode,
                                .musicVideo,
                                .video,
                                .liveTvProgram,
                                .tvChannel,
                                .person,
                            ],
                            parent: BaseItemDto(name: element.displayTitle),
                            environment: .init(filters: .init(genres: [element]))
                        )
                    )
                )
            }
        }

        if let studios = item.studios, studios.isNotEmpty {
            PillGroup(
                displayTitle: L10n.studios,
                id: "studios",
                elements: studios
            ) { router, element in
                router.route(
                    to: .contentGroup(
                        provider: ItemTypeContentGroupProvider(
                            itemTypes: [
                                BaseItemKind.movie,
                                .series,
                                .boxSet,
                                .episode,
                                .musicVideo,
                                .video,
                                .liveTvProgram,
                                .tvChannel,
                                .person,
                            ],
                            parent: BaseItemDto(id: element.id, name: element.displayTitle, type: .studio)
                        )
                    )
                )
            }
        }

        switch item.type {
        case .movie:
            if item.partCount ?? 0 > 1 {
                PosterGroup(
                    id: "additional-parts",
                    library: AdditionalPartsLibrary(itemID: itemID),
                    posterDisplayType: .landscape,
                    posterSize: .small
                )
            }
        case .boxSet, .person, .musicArtist:
            try await ItemTypeContentGroupProvider(
                itemTypes: BaseItemKind.supportedCases
                    .appending(.episode)
                    .appending(.person),
                parent: item
            )
            .makeGroups(environment: .default)
        case .series:
            try await ItemTypeContentGroupProvider(
                itemTypes: [.season],
                parent: item
            )
            .makeGroups(environment: .default)
        case .channel, .liveTvChannel, .tvChannel:
            PosterGroup(
                id: "channel-programs",
                library: ChannelProgramsLibrary(channel: item),
                posterDisplayType: .landscape,
                posterSize: .small
            )
        default: []
        }

        if item.type == .episode {
            PosterGroup(
                library: StaticLibrary(
                    title: L10n.season,
                    id: "seasons",
                    elements: [BaseItemDto(
                        id: item.seasonID,
                        name: item.seasonName,
                        seriesID: item.seriesID,
                        seriesName: item.seriesName,
                        type: .season
                    )]
                ),
                posterSize: .small,
                environment: .init(isHeaderButtonEnabled: false)
            )
        }

        if let castAndCrew = item.people, castAndCrew.isNotEmpty {
            PosterGroup(
                id: "cast-and-crew",
                library: StaticLibrary(
                    title: L10n.castAndCrew.localizedCapitalized,
                    id: "cast-and-crew",
                    elements: castAndCrew
                ),
                posterDisplayType: .portrait,
                posterSize: .small
            )
        }

        PosterGroup(
            id: "special-features",
            library: SpecialFeaturesLibrary(itemID: itemID),
            posterDisplayType: .landscape,
            posterSize: .small
        )

        PosterGroup(
            id: "similar-items",
            library: SimilarItemsLibrary(itemID: itemID),
            posterDisplayType: .landscape,
            posterSize: .small
        )

        AboutItemGroup(
            displayTitle: L10n.about,
            id: "about",
            item: item
        )
    }

    func toggleIsFavorite() async {
        let beforeIsFavorite = item.userData?.isFavorite ?? false

        item.userData?.isFavorite = !beforeIsFavorite
        do {
            try await setIsFavorite(!beforeIsFavorite)
        } catch {
            item.userData?.isFavorite = beforeIsFavorite
        }
    }

    func toggleIsPlayed() async {
        let beforeIsPlayed = item.userData?.isPlayed ?? false

        item.userData?.isPlayed = !beforeIsPlayed
        do {
            try await setIsPlayed(!beforeIsPlayed)
        } catch {
            item.userData?.isPlayed = beforeIsPlayed
        }
    }

    private func setPlayButtonItem(_ item: BaseItemDto?) {
        playButtonItem = item
        selectedMediaSource = item?.mediaSources?.first
    }

    private func playButtonItem(for item: BaseItemDto) async throws -> BaseItemDto? {
        switch item.type {
        case .series:
            if let nextUp = try await nextUpItem(for: item) {
                return nextUp
            }

            if let resumeItem = try await resumeItem(for: item) {
                return resumeItem
            }

            return try await firstAvailableItem(for: item)
        case .season:
            if let resumeItem = try await resumeItem(for: item) {
                return resumeItem
            }

            return try await firstAvailableItem(for: item)
        default:
            return item.isPlayable ? item : nil
        }
    }

    private func nextUpItem(for item: BaseItemDto) async throws -> BaseItemDto? {
        var parameters = Paths.GetNextUpParameters()
        parameters.fields = .MinimumFields
        parameters.seriesID = item.id

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await send(request)

        guard let item = response.value.items?.first, !item.isMissing else {
            return nil
        }

        return item
    }

    private func resumeItem(for item: BaseItemDto) async throws -> BaseItemDto? {
        var parameters = Paths.GetResumeItemsParameters()
        parameters.fields = .MinimumFields
        parameters.limit = 1
        parameters.parentID = item.id

        let request = Paths.getResumeItems(parameters: parameters)
        let response = try await send(request)

        return response.value.items?.first
    }

    private func firstAvailableItem(for item: BaseItemDto) async throws -> BaseItemDto? {
        var parameters = Paths.GetItemsParameters()
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.episode]
        parameters.isMissing = false
        parameters.isRecursive = true
        parameters.limit = 1
        parameters.parentID = item.id
        parameters.sortOrder = [.ascending]

        let request = Paths.getItems(parameters: parameters)
        let response = try await send(request)

        return response.value.items?.first
    }

    private func localTrailers(for item: BaseItemDto) async throws -> [BaseItemDto] {
        guard let itemID = item.id else { return [] }

        let request = try Paths.getLocalTrailers(itemID: itemID, userID: authenticatedUser.id)
        let response = try await send(request)

        return response.value
    }

    private func randomBackdropItem(for item: BaseItemDto) async throws -> BaseItemDto? {
        guard item.type == .person || item.type == .musicArtist || item.type == .boxSet else {
            return nil
        }

        var parameters = Paths.GetItemsParameters()
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = 1
        parameters.sortBy = [.random]
        parameters.userID = try authenticatedUser.id

        switch item.libraryType {
        case .boxSet, .collectionFolder, .userView:
            parameters.parentID = item.id
        case .person:
            parameters.personIDs = item.id.map { [$0] }
        default:
            parameters.parentID = item.id
        }

        let request = Paths.getItems(parameters: parameters)
        let response = try await send(request)

        return response.value.items?.first
    }

    private func setIsPlayed(_ isPlayed: Bool) async throws {
        guard let itemID = item.id else { return }

        let request: Request<UserItemDataDto> = if isPlayed {
            try Paths.markPlayedItem(
                itemID: itemID,
                userID: authenticatedUser.id
            )
        } else {
            try Paths.markUnplayedItem(
                itemID: itemID,
                userID: authenticatedUser.id
            )
        }

        let response = try await send(request)
        Notifications[.itemUserDataDidChange].post(response.value)
        Notifications[.itemShouldRefreshMetadata].post(itemID)
    }

    private func setIsFavorite(_ isFavorite: Bool) async throws {
        guard let itemID = item.id else { return }

        let request: Request<UserItemDataDto> = if isFavorite {
            try Paths.markFavoriteItem(
                itemID: itemID,
                userID: authenticatedUser.id
            )
        } else {
            try Paths.unmarkFavoriteItem(
                itemID: itemID,
                userID: authenticatedUser.id
            )
        }

        let response = try await send(request)
        Notifications[.itemUserDataDidChange].post(response.value)
        Notifications[.itemShouldRefreshMetadata].post(itemID)
    }
}

extension ItemContentGroupProvider: Recordable {

    var recordableItem: BaseItemDto {
        item
    }

    func setRecordingTimerID(_ timerID: String?) {
        switch item.type {
        case .channel, .liveTvChannel, .tvChannel:
            item.currentProgram?.timerID = timerID
        default:
            item.timerID = timerID
        }
    }
}
