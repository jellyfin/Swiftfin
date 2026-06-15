//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

@MainActor
struct ItemLibrary: PagingLibrary, SearchablePagingLibrary, WithRandomElementLibrary {

    struct Environment: WithDefaultValue {
        var filters: ItemFilterCollection

        static let `default`: Self = .init(filters: .default)
    }

    let environment: Environment?
    let isFilterable: Bool
    let parent: AnyLibraryParent

    init(
        parent: some LibraryParent,
        filters: ItemFilterCollection? = nil
    ) {
        self.environment = .init(filters: filters ?? .default)
        self.isFilterable = filters != nil
        self.parent = .init(parent)
    }

    func makeFilterViewModel(environment: Environment) -> FilterViewModel? {
        guard isFilterable else { return nil }

        var filters = environment.filters

        if let id = parent.id, Defaults[.Customization.Library.rememberSort] {
            let storedFilters = StoredValues[.User.libraryFilters(parentID: id)]

            filters.sortBy = storedFilters.sortBy
            filters.sortOrder = storedFilters.sortOrder
        }

        return FilterViewModel(
            parent: parent,
            currentFilters: filters
        )
    }

    func setFilters(
        _ filters: ItemFilterCollection,
        on environment: inout Environment
    ) {
        environment.filters = filters
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = attachPage(
            to: attachFilters(
                to: makeBaseItemParameters(),
                using: environment.filters
            ),
            pageState: pageState
        )
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return normalize(response.value.items ?? [])
    }

    func retrieveRandomElement(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> BaseItemDto? {
        var parameters = attachFilters(
            to: makeBaseItemParameters(),
            using: environment.filters
        )
        parameters.limit = 1
        parameters.sortBy = [.random]
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items?.first
    }

    func retrieveSearchPage(
        query: String,
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = attachPage(
            to: attachFilters(
                to: makeBaseItemParameters(),
                using: environment.filters,
                isLetterFilterIncluded: false
            ),
            pageState: pageState
        )
        parameters.searchTerm = query
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return normalize(response.value.items ?? [])
    }

    private func makeBaseItemParameters() -> Paths.GetItemsParameters {
        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = BaseItemKind.supportedCases
        parameters.isRecursive = parent.isRecursiveCollection
        parameters.sortBy = [.name]
        parameters.sortOrder = [.ascending]

        return parent.setParentParameters(parameters)
    }

    private func normalize(_ items: [BaseItemDto]) -> [BaseItemDto] {
        items
            .filter { item in
                if let collectionType = item.collectionType {
                    return CollectionType.supportedCases.contains(collectionType)
                }

                return true
            }
            .map { item in
                if parent.libraryType == .folder, item.type == .collectionFolder {
                    return item.mutating(\.type, with: .folder)
                }

                return item
            }
    }

    private func attachFilters(
        to parameters: Paths.GetItemsParameters,
        using filters: ItemFilterCollection,
        isLetterFilterIncluded: Bool = true
    ) -> Paths.GetItemsParameters {
        var parameters = parameters
        parameters.filters = filters.traits
        parameters.genres = filters.genres.map(\.value)
        parameters.sortBy = filters.sortBy
        parameters.sortOrder = filters.sortOrder
        parameters.tags = filters.tags.map(\.value)
        parameters.years = filters.years.compactMap { Int($0.value) }

        if filters.itemTypes.isNotEmpty {
            parameters.includeItemTypes = filters.itemTypes
        }

        guard isLetterFilterIncluded else { return parameters }

        if filters.letter.first?.value == "#" {
            parameters.nameLessThan = "A"
        } else {
            parameters.nameStartsWith = filters.letter
                .map(\.value)
                .filter { $0 != "#" }
                .first
        }

        return parameters
    }

    private func attachPage(
        to parameters: Paths.GetItemsParameters,
        pageState: LibraryPageState
    ) -> Paths.GetItemsParameters {
        var parameters = parameters
        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset
        return parameters
    }
}
