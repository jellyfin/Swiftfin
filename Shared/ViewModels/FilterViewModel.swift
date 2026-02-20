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

final class FilterViewModel: ViewModel, Stateful {

    // MARK: - Action

    enum Action: Equatable {
        case cancel
        case getQueryFilters
        case reset(ItemFilterType? = nil)
        case update(ItemFilterType, [AnyItemFilter])
    }

    // MARK: - Background State

    enum BackgroundState: Hashable {
        case gettingQueryFilters
        case failedToGetQueryFilters
    }

    // MARK: - State

    enum State: Hashable {
        case content
    }

    /// Tracks the current filters
    @Published
    private(set) var currentFilters: ItemFilterCollection

    /// All filters available
    @Published
    private(set) var allFilters: ItemFilterCollection = .all

    /// ViewModel Background State(s)
    @Published
    var backgroundStates: Set<BackgroundState> = []

    /// ViewModel State
    @Published
    var state: State = .content

    private let parent: (any LibraryParent)?

    private var queryFiltersTask: AnyCancellable?

    // MARK: - Initialize from Library Parent

    init(
        parent: (any LibraryParent)? = nil,
        currentFilters: ItemFilterCollection = .default
    ) {
        self.parent = parent
        self.currentFilters = currentFilters

        super.init()

        if let parent {
            self.allFilters.itemTypes = parent.supportedItemTypes
        }
    }

    func isFilterSelected(type: ItemFilterType) -> Bool {
        currentFilters[keyPath: type.collectionAnyKeyPath] != ItemFilterCollection.default[keyPath: type.collectionAnyKeyPath]
    }

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            queryFiltersTask?.cancel()
            backgroundStates.removeAll()

        case .getQueryFilters:
            queryFiltersTask?.cancel()
            queryFiltersTask = Task {
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.insert(.gettingQueryFilters)
                    }

                    try await setQueryFilters()
                } catch {
                    await MainActor.run {
                        _ = self.backgroundStates.insert(.failedToGetQueryFilters)
                    }
                }

                await MainActor.run {
                    _ = self.backgroundStates.remove(.gettingQueryFilters)
                }
            }
            .asAnyCancellable()

        case let .reset(type):
            if let type {
                resetCurrentFilters(for: type)
            } else {
                currentFilters = .default
            }

        case let .update(type, filters):
            updateCurrentFilters(for: type, with: filters)
        }

        return state
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
    private func setQueryFilters() async throws {
        let queryFilters = try await getQueryFilters()

        await MainActor.run {
            allFilters.genres = queryFilters.genres
            allFilters.tags = queryFilters.tags
            allFilters.years = queryFilters.years
        }
    }

    // MARK: - Get Query Filters

    /// Gets the query filters from the parent
    private func getQueryFilters() async throws -> (genres: [ItemGenre], tags: [ItemTag], years: [ItemYear]) {

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

        return (genres, tags, years)
    }
}
