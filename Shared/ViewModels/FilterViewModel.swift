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

    /// Fixed filters, excluded from selection state and reset actions
    let staticFilters: ItemFilterCollection

    private let parent: (any LibraryParent)?

    var hasActiveFilters: Bool {
        staticFilters.union(currentFilters) != staticFilters
    }

    private var itemTypes: [BaseItemKind] {
        staticFilters.itemTypes.isEmpty ?
            parent?.supportedItemTypes ?? BaseItemKind.supportedCases :
            staticFilters.itemTypes
    }

    init(
        parent: (any LibraryParent)? = nil,
        currentFilters: ItemFilterCollection = .default,
        staticFilters: ItemFilterCollection = .default
    ) {
        self.parent = parent
        self.currentFilters = currentFilters
        self.staticFilters = staticFilters

        super.init()
    }

    func isFilterSelected(type: ItemFilterType) -> Bool {
        guard !staticFilters.containsFilters(ofType: type) else { return false }

        return currentFilters.containsFilters(ofType: type)
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
    }

    private func getFiltersLegacy() async throws {

        let parameters = try Paths.GetQueryFiltersLegacyParameters(
            userID: authenticatedUser.id,
            parentID: parent?.id,
            includeItemTypes: itemTypes
        )

        let request = Paths.getQueryFiltersLegacy(parameters: parameters)
        let response = try await send(request)

        let officialRatings = (response.value.officialRatings ?? [])
            .map(ItemOfficialRating.init)

        // Manually sort so that most recent years are "first"
        let years = (response.value.years ?? [])
            .sorted(by: >)
            .map(ItemYear.init)

        allFilters.officialRatings = officialRatings
        allFilters.years = years
    }

    private func getFilters() async throws {

        let parameters = try Paths.GetQueryFiltersParameters(
            userID: authenticatedUser.id,
            parentID: parent?.id,
            includeItemTypes: itemTypes,
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
}
