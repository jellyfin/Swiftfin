//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

@MainActor
struct PagingItemLibrary: PagingLibrary, WithRandomElementLibrary {

    struct Environment: WithDefaultValue {
        let grouping: Parent.Grouping?
        let filters: ItemFilterCollection

        static var `default`: Self {
            .init(
                grouping: nil,
                filters: .default
            )
        }
    }

    let environment: Environment?
    let filterViewModel: FilterViewModel
    let parent: BaseItemDto

    init(
        parent: Parent,
        filters: ItemFilterCollection? = nil
    ) {
        if parent.groupings?.defaultSelection != nil || filters != nil {
            environment = .init(
                grouping: parent.groupings?.defaultSelection,
                filters: filters ?? .default
            )
        } else {
            environment = nil
        }

        self.filterViewModel = .init(
            parent: parent,
            currentFilters: environment?.filters ?? .default
        )

        self.parent = parent
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {

        let parameters = attachPage(
            to: attachFilters(
                to: makeBaseItemParameters(environment: environment),
                using: self.environment?.filters ?? environment.filters,
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
        environment: Environment
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

        if filters.mediaTypes.isNotEmpty {
            parameters.mediaTypes = filters.mediaTypes.map(\.rawValue).nilIfEmpty
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
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> BaseItemDto? {
        var parameters = attachFilters(
            to: makeBaseItemParameters(environment: environment),
            using: self.environment?.filters ?? environment.filters,
            pageState: pageState
        )

        parameters.limit = 1
        parameters.sortBy = [ItemSortBy.random.rawValue]

        let request = Paths.getItemsByUserID(
            userID: pageState.userSession.user.id,
            parameters: parameters
        )
        let response = try? await pageState.userSession.client.send(request)

        return response?.value.items?.first
    }

    func makeLibraryBody(content: some View) -> AnyView {
        WithRouter { router in
            content
                .navigationBarFilterDrawer(
                    viewModel: filterViewModel,
                    types: ItemFilterType.allCases
                ) {
                    router.route(to: .filter(type: $0.type, viewModel: $0.viewModel))
                }
        }
        .eraseToAnyView()
    }

    @MenuContentGroupBuilder
    func menuContent(environment: Binding<Environment>) -> [MenuContentGroup] {
        if let groupings = parent.groupings, groupings.elements.isNotEmpty {
            MenuContentGroup(id: "grouping") {

                let binding = Binding<Parent.Grouping?>(
                    get: { environment.wrappedValue.grouping },
                    set: { environment.wrappedValue = Environment(
                        grouping: $0,
                        filters: environment.wrappedValue.filters
                    ) }
                )

                Picker(selection: binding) {
                    ForEach(groupings.elements) { grouping in
                        Text(grouping.displayTitle)
                            .tag(grouping as Parent.Grouping?)
                    }
                } label: {
                    Text("Grouping")

                    if let grouping = environment.wrappedValue.grouping {
                        Text(grouping.displayTitle)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}
