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

final class FilterViewModel: ViewModel, Stateful {

    // MARK: - Action

    enum Action: Equatable {
        case refresh
        case cancel
        case reset(ItemFilterType? = nil)
        case update(ItemFilterType, [AnyItemFilter])
    }

    // MARK: - Background State

    enum BackgroundState: Hashable {
        case refreshing
        case updating
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case content
    }

    /// Tracks the current filters
    @Published
    var currentFilters: ItemFilterCollection

    /// Tracks modified filters as a tuple of value and modification state
    @Published
    var modifiedFilters: Set<ItemFilterType>

    /// All filters available
    @Published
    var allFilters: ItemFilterCollection = .all

    /// ViewModel Background State(s)
    @Published
    var backgroundStates: OrderedSet<BackgroundState> = []

    /// ViewModel State
    @Published
    var state: State = .initial

    // MARK: - Filter Variables

    private let parent: (any LibraryParent)?

    // MARK: - Tasks

    private var backgroundTask: AnyCancellable?
    private var task: AnyCancellable?

    // MARK: - Initialize from Library Parent

    init(
        parent: (any LibraryParent)? = nil,
        currentFilters: ItemFilterCollection = .default
    ) {
        self.parent = parent
        self.currentFilters = currentFilters

        let defaultFilters: ItemFilterCollection = .default

        var modifiedFiltersSet: Set<ItemFilterType> = []

        for type in ItemFilterType.allCases {
            let isModified = currentFilters[keyPath: type.collectionAnyKeyPath] != defaultFilters[keyPath: type.collectionAnyKeyPath]
            if isModified {
                modifiedFiltersSet.insert(type)
            }
        }

        self.modifiedFilters = modifiedFiltersSet

        super.init()

        if let parent {
            self.allFilters.itemTypes = parent.supportedItemTypes
        }
    }

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            backgroundTask?.cancel()
            task?.cancel()

            return state

        case .refresh:
            backgroundTask?.cancel()
            backgroundTask = Task {
                do {
                    await MainActor.run {
                        self.state = .initial
                        _ = self.backgroundStates.append(.refreshing)
                    }

                    await self.setQueryFilters()

                    await MainActor.run {
                        self.state = .content
                        _ = self.backgroundStates.remove(.refreshing)
                    }
                }
            }
            .asAnyCancellable()

            return state

        case let .reset(type):
            task?.cancel()
            task = Task {
                await MainActor.run {
                    _ = backgroundStates.append(.updating)
                }

                if let type {
                    resetCurrentFilters(for: type)
                    toggleModifiedState(for: type)
                } else {
                    self.currentFilters = .default
                    self.modifiedFilters.removeAll()
                }

                await MainActor.run {
                    _ = backgroundStates.remove(.updating)
                }
            }
            .asAnyCancellable()

            return state

        case let .update(type, filters):
            task?.cancel()
            task = Task {
                do {
                    await MainActor.run {
                        _ = backgroundStates.append(.updating)
                    }

                    updateCurrentFilters(for: type, with: filters)
                    toggleModifiedState(for: type)

                    await MainActor.run {
                        _ = backgroundStates.remove(.updating)
                    }
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Toggle Modified Filter State

    /// Check if the current filter for a specific type has been modified and update `modifiedFilters`
    private func toggleModifiedState(for type: ItemFilterType) {

        if currentFilters[keyPath: type.collectionAnyKeyPath] != ItemFilterCollection.default[keyPath: type.collectionAnyKeyPath] {
            self.modifiedFilters.insert(type)
        } else {
            self.modifiedFilters.remove(type)
        }
    }

    // MARK: - Reset Current Filters

    /// Reset the filter for a specific type to its default value
    private func resetCurrentFilters(for type: ItemFilterType) {
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

    // MARK: - Update Current Filters

    /// Update the filter for a specific type with new values
    private func updateCurrentFilters(for type: ItemFilterType, with newValue: [AnyItemFilter]) {
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
            currentFilters.traits = newValue.map(ItemTrait.init)
        case .years:
            currentFilters.years = newValue.map(ItemYear.init)
        }
    }

    // MARK: - Set Query Filters

    /// Sets the query filters from the parent
    private func setQueryFilters() async {
        let queryFilters = await getQueryFilters()

        await MainActor.run {
            allFilters.genres = queryFilters.genres
            allFilters.tags = queryFilters.tags
            allFilters.years = queryFilters.years
        }
    }

    // MARK: - Get Query Filters

    /// Gets the query filters from the parent
    private func getQueryFilters() async -> (genres: [ItemGenre], tags: [ItemTag], years: [ItemYear]) {

        let parameters = Paths.GetQueryFiltersLegacyParameters(
            userID: userSession.user.id,
            parentID: parent?.id
        )

        let request = Paths.getQueryFiltersLegacy(parameters: parameters)
        guard let response = try? await userSession.client.send(request) else { return ([], [], []) }

        let genres: [ItemGenre] = (response.value.genres ?? [])
            .map(ItemGenre.init)

        let tags = (response.value.tags ?? [])
            .map(ItemTag.init)

        // Manually sort so that most recent years are "first"
        let years = (response.value.years ?? [])
            .sorted(by: >)
            .map(ItemYear.init)

        return (genres, tags, years)
    }
}
