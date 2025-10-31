//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
//        case update(ItemFilterType, [AnyItemFilter])

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
    var currentFilters: ItemFilterCollection {
        didSet {
            currentFiltersSubject.send(currentFilters)
        }
    }

    var currentFiltersDebounced: AnyPublisher<ItemFilterCollection, Never> {
        currentFiltersSubject
            .debounce(for: 1, scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private var currentFiltersSubject: PassthroughSubject<ItemFilterCollection, Never> = .init()

    private let parent: (any _LibraryParent)?

    init(
        parent: (any _LibraryParent)? = nil,
        currentFilters: ItemFilterCollection = .default
    ) {
        self.parent = parent
        self.currentFilters = currentFilters

        super.init()

//        if let parent {
//            self.allFilters.itemTypes = parent._supportedItemTypes(
//                for: parent._groupings?.defaultSelection
//            )
//        }
    }

    func isFilterSelected(type: ItemFilterType) -> Bool {
        currentFilters[keyPath: type.collectionAnyKeyPath] != ItemFilterCollection.default[keyPath: type.collectionAnyKeyPath]
    }

    @Function(\Action.Cases.reset)
    private func resetCurrentFilters(_ type: ItemFilterType?) {

        guard let type else {
            currentFilters = .default
            return
        }

        switch type {
        case .genres:
            currentFilters.genres = ItemFilterCollection.default.genres
        case .letter:
            currentFilters.letter = ItemFilterCollection.default.letter
        case .sortBy:
            currentFilters.sortBy = ItemFilterCollection.default.sortBy
        case .sortOrder:
            currentFilters.sortOrder = ItemFilterCollection.default.sortOrder
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

        let parameters = Paths.GetQueryFiltersLegacyParameters(
            userID: userSession.user.id,
            parentID: parent?.libraryID
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
