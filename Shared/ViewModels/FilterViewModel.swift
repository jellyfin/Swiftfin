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

    /// The filters this view model was created with.
    ///
    /// These describe the library itself, such as a fixed item type, and are
    /// what a reset restores instead of the global default collection.
    let baseFilters: ItemFilterCollection

    private let parent: (any LibraryParent)?

    init(
        parent: (any LibraryParent)? = nil,
        currentFilters: ItemFilterCollection = .default
    ) {
        self.baseFilters = currentFilters
        self.parent = parent
        self.currentFilters = currentFilters

        super.init()
    }

    /// Whether any filter differs from the filters the library was created with.
    var hasActiveFilters: Bool {
        currentFilters != baseFilters
    }

    func isFilterSelected(type: ItemFilterType) -> Bool {
        type.group
            .map(\.keyPath)
            .contains { keyPath in
                currentFilters[keyPath: keyPath] != baseFilters[keyPath: keyPath]
            }
    }

    @Function(\Action.Cases.reset)
    private func resetCurrentFilters(_ type: ItemFilterType?) {

        guard let type else {
            currentFilters = baseFilters
            return
        }

        switch type {
        case .audioLanguage:
            currentFilters.audioLanguages = baseFilters.audioLanguages
        case .category:
            currentFilters.categories = baseFilters.categories
        case .genres:
            currentFilters.genres = baseFilters.genres
        case .letter:
            currentFilters.letter = baseFilters.letter
        case .officialRatings:
            currentFilters.officialRatings = baseFilters.officialRatings
        case .sortBy:
            currentFilters.sortBy = baseFilters.sortBy
            currentFilters.sortOrder = baseFilters.sortOrder
        case .subtitleLanguage:
            currentFilters.subtitleLanguages = baseFilters.subtitleLanguages
        case .tags:
            currentFilters.tags = baseFilters.tags
        case .traits:
            currentFilters.traits = baseFilters.traits
        case .years:
            currentFilters.years = baseFilters.years
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
            includeItemTypes: parent?.supportedItemTypes ?? BaseItemKind.supportedCases
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
}
