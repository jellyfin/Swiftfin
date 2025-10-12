//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct PagingItemLibrary: PagingLibrary, WithRandomElementLibrary {

    let parent: BaseItemDto

    // TODO: remove, as provider should pass in data through environment
    let filterViewModel: FilterViewModel?

    init(
        parent: Parent,
        filters: FilterViewModel?
    ) {
        self.parent = parent
        self.filterViewModel = filters
    }

    func retrievePage(
        environment: BaseItemLibraryEnvironment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {

        if pageState.page == 0 {
            async let _ = try? filterViewModel?.getQueryFilters()
        }

        let parameters = await attachPage(
            to: attachFilters(
                to: makeBaseItemParameters(environment: environment),
                using: filterViewModel?.currentFilters ?? environment.filters,
                pageState: pageState
            ),
            pageState: pageState
        )

        let request = Paths.getItemsByUserID(
            userID: pageState.userSession.user.id,
            parameters: parameters
        )
        let response = try await pageState.userSession.client.send(
            request
        )

        // TODO: cleanup below

        // 1 - only keep collections that hold valid items
        // 2 - if parent is type `folder`, then we are in a folder-view
        //     context so change `collectionFolder` types to `folder`
        //     for better view handling
        let elements = (response.value.items ?? [])
//            .filter { $0.collectionType?.isSupported == true }
        //            .filter { $0.collectionType?.isSupported ?? true }
        //            .map { item in
        //                if parent.libraryType == .folder, item.type == .collectionFolder {
        //                    return item.mutating(\.type, with: .folder)
        //                }
        //
        //                return item
        //            }

        return elements
    }

    private func makeBaseItemParameters(
        environment: BaseItemLibraryEnvironment
    ) -> Paths.GetItemsByUserIDParameters {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true

        // Default values, expected to be overridden
        // by parent or filters
        parameters.includeItemTypes = BaseItemKind.supportedCases
        parameters.sortOrder = [.ascending]
        parameters.sortBy = [ItemSortBy.name.rawValue]

        /// Recursive should only apply to parents/folders and not to baseItems
        parameters.isRecursive = parent._isRecursiveCollection(for: environment.grouping)
        parameters.includeItemTypes = parent._supportedItemTypes(for: environment.grouping)

        if let parentID = parent.id, let parentType = parent.type {
            switch parentType {
            case .boxSet, .collectionFolder, .userView:
                parameters.parentID = parentID
            case .folder:
                parameters.parentID = parentID
                parameters.isRecursive = nil
            case .person:
                parameters.personIDs = [parentID]
            case .studio:
                parameters.studioIDs = [parentID]
            default: ()
            }
        }

        return parameters
    }

    func attachFilters(
        to parameters: Paths.GetItemsByUserIDParameters,
        using filters: ItemFilterCollection,
        pageState: LibraryPageState
    ) -> Paths.GetItemsByUserIDParameters {

        var parameters = parameters
        parameters.filters = filters.traits.nilIfEmpty
        parameters.genres = filters.genres.map(\.value).nilIfEmpty
        parameters.searchTerm = filters.query
        parameters.sortBy = filters.sortBy.map(\.rawValue).nilIfEmpty
        parameters.sortOrder = filters.sortOrder.nilIfEmpty
        parameters.tags = filters.tags.map(\.value).nilIfEmpty
        parameters.years = filters.years.compactMap { Int($0.value) }.nilIfEmpty

        // Only set filtering on item types if selected
        if filters.itemTypes.isNotEmpty {
            parameters.includeItemTypes = filters.itemTypes.nilIfEmpty
        }

        if filters.letter.first?.value == "#" {
            parameters.nameLessThan = "A"
        } else if filters.letter.isNotEmpty {
            parameters.nameStartsWith = filters.letter
                .map(\.value)
                .filter { $0 != "#" }
                .first
        }

        return parameters
    }

    private func attachPage(
        to parameters: Paths.GetItemsByUserIDParameters,
        pageState: LibraryPageState
    ) -> Paths.GetItemsByUserIDParameters {
        var parameters = parameters
        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset
        return parameters
    }

    func retrieveRandomElement(
        environment: BaseItemLibraryEnvironment,
        pageState: LibraryPageState
    ) async throws -> BaseItemDto? {
        var parameters = attachFilters(
            to: makeBaseItemParameters(environment: environment),
            using: environment.filters,
            pageState: pageState
        )

        parameters.limit = 1
        parameters.sortBy = [ItemSortBy.random.rawValue]

        let request = Paths.getItemsByUserID(userID: pageState.userSession.user.id, parameters: parameters)
        let response = try? await pageState.userSession.client.send(request)

        return response?.value.items?.first
    }
}
