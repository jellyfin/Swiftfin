//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
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
        case update(filterType: ItemFilterType, filters: [AnyItemFilter])

        var transition: Transition {
            switch self {
            case .cancel, .reset, .update: .none
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

        if let type {
            switch type {
            case .genres:
                currentFilters.genres = ItemFilterCollection.default.genres
            case .letter:
                currentFilters.letter = ItemFilterCollection.default.letter
            case .sortBy:
                currentFilters.sortBy = ItemFilterCollection.default.sortBy
                currentFilters.sortOrder = ItemFilterCollection.default.sortOrder
            case .tags:
                currentFilters.tags = ItemFilterCollection.default.tags
            case .traits:
                currentFilters.traits = ItemFilterCollection.default.traits
            case .years:
                currentFilters.years = ItemFilterCollection.default.years
            }
        } else {
            currentFilters = .default
        }

        // Clear stored filters when rememberFiltering is enabled
        if let id = parent?.id, Defaults[.Customization.Library.rememberFiltering] {
            var storedFilters = StoredValues[.User.libraryFilters(parentID: id)]

            if let type {
                switch type {
                case .genres:
                    storedFilters.genres = ItemFilterCollection.default.genres
                case .letter:
                    storedFilters.letter = ItemFilterCollection.default.letter
                case .sortBy:
                    storedFilters.sortBy = ItemFilterCollection.default.sortBy
                    storedFilters.sortOrder = ItemFilterCollection.default.sortOrder
                case .tags:
                    storedFilters.tags = ItemFilterCollection.default.tags
                case .traits:
                    storedFilters.traits = ItemFilterCollection.default.traits
                case .years:
                    storedFilters.years = ItemFilterCollection.default.years
                }
            } else {
                storedFilters.genres = ItemFilterCollection.default.genres
                storedFilters.letter = ItemFilterCollection.default.letter
                storedFilters.tags = ItemFilterCollection.default.tags
                storedFilters.traits = ItemFilterCollection.default.traits
                storedFilters.years = ItemFilterCollection.default.years
            }

            StoredValues[.User.libraryFilters(parentID: id)] = storedFilters
        }
    }

    @Function(\Action.Cases.update)
    private func updateCurrentFilters(_ type: ItemFilterType, _ newValue: [AnyItemFilter]) {
        switch type {
        case .genres:
            currentFilters.genres = newValue.map(ItemGenre.init)
        case .letter:
            currentFilters.letter = newValue.map(ItemLetter.init)
        case .sortBy:
            currentFilters.sortBy = newValue.map(ItemSortBy.init)
        case .sortOrder:
            currentFilters.sortOrder = newValue.map(ItemSortOrder.init)
        case .tags:
            currentFilters.tags = newValue.map(ItemTag.init)
        case .traits:
            var traits = newValue.map(ItemTrait.init)

            let isPlayedSelected = traits.contains(.isPlayed)
            let isUnplayedSelected = traits.contains(.isUnplayed)

            if isPlayedSelected && isUnplayedSelected {
                let oldTraits = currentFilters.traits
                let oldHasPlayed = oldTraits.contains(.isPlayed)
                let oldHasUnplayed = oldTraits.contains(.isUnplayed)

                if oldHasUnplayed {
                    traits.removeAll { $0 == .isUnplayed }
                } else if oldHasPlayed {
                    traits.removeAll { $0 == .isPlayed }
                } else {
                    traits.removeAll { $0 == .isUnplayed }
                }
            }

            currentFilters.traits = traits
        case .years:
            currentFilters.years = newValue.map(ItemYear.init)
        }
    }

    @Function(\Action.Cases.getQueryFilters)
    private func _getQueryFilters() async throws {

        let parameters = Paths.GetQueryFiltersLegacyParameters(
            userID: userSession.user.id,
            parentID: parent?.id
        )

        let request = Paths.getQueryFiltersLegacy(parameters: parameters)
        let response = try await userSession.client.send(request)

        let genres: [ItemGenre] = (response.value.genres ?? [])
            .map(ItemGenre.init)

        let tags = (response.value.tags ?? [])
            .map(ItemTag.init)

        // Manually sort so that most recent years are "first"
        let years = (response.value.years ?? [])
            .sorted(by: >)
            .map(ItemYear.init)

        allFilters.genres = genres
        allFilters.tags = tags
        allFilters.years = years
    }
}
