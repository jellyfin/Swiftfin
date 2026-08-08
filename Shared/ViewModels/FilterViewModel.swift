//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

@MainActor
@Stateful
final class FilterViewModel: ViewModel {

    @CasePathable
    enum Action {
        case cancel
        case getQueryFilters
        case reset(filterType: ItemFilterType?)

        var transition: Transition {
            switch self {
            case .cancel, .reset: .none
            case .getQueryFilters:
                .background(.retrievingQueryFilters)
            }
        }
    }

    enum BackgroundState {
        case retrievingQueryFilters
    }

    @Published
    private(set) var allFilters: ItemFilterCollection = .all
    @Published
    var currentFilters: ItemFilterCollection

    private let parent: (any LibraryParent)?

    init(
        parent: (any LibraryParent)? = nil,
        currentFilters: ItemFilterCollection = .default
    ) {
        self.parent = parent
        self.currentFilters = currentFilters

        super.init()
    }

    func isFilterSelected(type: ItemFilterType) -> Bool {
        type.group
            .map(\.keyPath)
            .contains { keyPath in
                currentFilters[keyPath: keyPath] != ItemFilterCollection.default[keyPath: keyPath]
            }
    }

    @Function(\Action.Cases.reset)
    private func resetCurrentFilters(_ type: ItemFilterType?) {

        guard let type else {
            currentFilters = .default
            return
        }

        switch type {
        case .audioLanguage:
            currentFilters.audioLanguages = ItemFilterCollection.default.audioLanguages
        case .category:
            currentFilters.categories = ItemFilterCollection.default.categories
        case .genres:
            currentFilters.genres = ItemFilterCollection.default.genres
        case .letter:
            currentFilters.letter = ItemFilterCollection.default.letter
        case .officialRatings:
            currentFilters.officialRatings = ItemFilterCollection.default.officialRatings
        case .sortBy:
            currentFilters.sortBy = ItemFilterCollection.default.sortBy
            currentFilters.sortOrder = ItemFilterCollection.default.sortOrder
        case .subtitleLanguage:
            currentFilters.subtitleLanguages = ItemFilterCollection.default.subtitleLanguages
        case .tags:
            currentFilters.tags = ItemFilterCollection.default.tags
        case .traits:
            currentFilters.traits = ItemFilterCollection.default.traits
        case .years:
            currentFilters.years = ItemFilterCollection.default.years
        }
    }

    @Function(\Action.Cases.getQueryFilters)
    private func _getQueryFilters() async throws {

        try await getFilters()
        try await getFiltersLegacy()
        try await getYears()
    }

    private func getFiltersLegacy() async throws {

        let parameters = try Paths.GetQueryFiltersLegacyParameters(
            userID: authenticatedUser.id,
            parentID: parent?.id,
            includeItemTypes: parent?.supportedItemTypes ?? BaseItemKind.supportedCases
        )

        let request = Paths.getQueryFiltersLegacy(parameters: parameters)
        let response = try await send(request)

        allFilters.officialRatings = (response.value.officialRatings ?? [])
            .map(ItemOfficialRating.init)
    }

    private func getFilters() async throws {

        let parameters = try Paths.GetQueryFiltersParameters(
            userID: authenticatedUser.id,
            parentID: parent?.id,
            includeItemTypes: parent?.supportedItemTypes ?? BaseItemKind.supportedCases,
            isRecursive: true
        )

        let request = Paths.getQueryFilters(parameters: parameters)
        let response = try await send(request)

        let audioLanguages: [ItemLanguage] = (response.value.audioLanguages ?? [])
            .compactMap(ItemLanguage.init)
            .sorted(using: \.displayTitle)

        let genres: [ItemGenre] = (response.value.genres ?? [])
            .compactMap(\.name)
            .map(ItemGenre.init)

        let subtitleLanguages: [ItemLanguage] = (response.value.subtitleLanguages ?? [])
            .compactMap(ItemLanguage.init)
            .sorted(using: \.displayTitle)

        let tags = (response.value.tags ?? [])
            .map(ItemTag.init)

        allFilters.audioLanguages = audioLanguages
        allFilters.genres = genres
        allFilters.subtitleLanguages = subtitleLanguages
        allFilters.tags = tags
    }

    private func getYears() async throws {

        let parameters = try Paths.GetYearsParameters(
            sortOrder: [SortOrder.descending],
            parentID: parent?.id,
            sortBy: [ItemSortBy.sortName],
            enableUserData: false,
            userID: authenticatedUser.id,
            isRecursive: true,
            enableImages: false
        )

        let request = Paths.getYears(parameters: parameters)
        let response = try await send(request)

        let years = (response.value.items ?? [])
            .compactMap(\.name)
            .map(ItemYear.init)

        allFilters.years = years
    }
}
