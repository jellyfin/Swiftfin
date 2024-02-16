//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Get
import JellyfinAPI
import SwiftUI
import UIKit

// TODO: Look at refactoring
class LibraryViewModel: PagingLibraryViewModel, Stateful {

    enum Action {
        case error(JellyfinAPIError)
        case getNextPage
        case getRandomItem
    }

    enum State {
        case error(JellyfinAPIError)
        case gettingFirstPage
        case gettingNextPage
        case gettingRandomItem
        case initial
    }

    deinit {
        print("LibraryViewModel.deinit")
    }

    let filterViewModel: FilterViewModel

    let parent: (any LibraryParent)?
    private let saveFilters: Bool
    var state: State

    func respond(to action: Action) -> State {
        switch action {}
    }

    var libraryCoordinatorParameters: LibraryCoordinator.Parameters {
        if let parent = parent {
            return .init(parent: parent, filters: filterViewModel.currentFilters)
        } else {
            return .init(filters: filterViewModel.currentFilters)
        }
    }

    convenience init(
        filters: ItemFilters,
        saveFilters: Bool = false
    ) {
        self.init(
            parent: nil,
            filters: filters,
            saveFilters: saveFilters
        )
    }

    init(
        parent: (any LibraryParent)?,
        filters: ItemFilters = .init(),
        saveFilters: Bool = false
    ) {
        self.parent = parent
        self.filterViewModel = .init(parent: parent, currentFilters: filters)
        self.saveFilters = saveFilters
        super.init()

        // TODO: call `refresh` instead
//        filterViewModel.$currentFilters
//            .debounce(for: 0.5, scheduler: DispatchQueue.main)
//            .sink { newFilters in
//
//                if self.saveFilters, let id = self.parent?.id {
//                    Defaults[.libraryFilterStore][id] = newFilters
//                }
//
//                print("got new filters?")
//
//                Task {
//                    print("refreshing from filter change")
//
//
//                }
//                .asAnyCancellable()
//                .store(in: &self.cancellables)
//            }
//            .store(in: &cancellables)
    }

    override func get(page: Int) async throws -> [BaseItemDto] {
        let parameters = getItemParameters(for: page)
        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        // 1 - only care to keep collections that hold valid items
        // 2 - if parent is type `folder`, then we are in a folder-view
        //     context so change `collectionFolder` types to `folder`
        //     for better view handling
        let validItems = (response.value.items ?? [])
            .filter { item in
                if let collectionType = item.collectionType {
                    return ["movies", "tvshows", "mixed", "boxsets"].contains(collectionType)
                }

                return true
            }
            .map { item in
                if parent?.libraryType == .folder, item.type == .collectionFolder {
                    return item.mutating(\.type, with: .folder)
                }

                return item
            }

        return validItems
    }

    func getItemParameters(for page: Int) -> Paths.GetItemsByUserIDParameters {

        let filters = filterViewModel.currentFilters
        var libraryID: String?
        var personIDs: [String]?
        var studioIDs: [String]?
        var includeItemTypes: [BaseItemKind]?
        var isRecursive: Bool? = true

        if let libraryType = parent?.libraryType, let id = parent?.id {
            switch libraryType {
            case .collectionFolder:
                libraryID = id
            case .folder, .userView:
                libraryID = id
                isRecursive = nil
            case .person:
                personIDs = [id]
            case .studio:
                studioIDs = [id]
            default: ()
            }
        }

        let genreIDs = filters.genres.compactMap(\.id)
        let itemFilters: [ItemFilter] = filters.filters.compactMap { .init(rawValue: $0.filterName) }

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.isRecursive = isRecursive
        parameters.parentID = libraryID
        parameters.fields = ItemFields.minimumCases
        parameters.includeItemTypes = includeItemTypes
        parameters.filters = itemFilters
        parameters.enableUserData = true
        parameters.personIDs = personIDs
        parameters.studioIDs = studioIDs
        parameters.genreIDs = genreIDs

        parameters.limit = Self.DefaultPageSize
        parameters.startIndex = page * Self.DefaultPageSize
        parameters.sortOrder = filters.sortOrder.map { SortOrder(rawValue: $0.filterName) ?? .ascending }
        parameters.sortBy = filters.sortBy.map(\.filterName).prepending("IsFolder")

        // Random sort won't take into account previous items, so
        // manual exclusion is necessary. This could possibly be
        // a performance issue for loading very large libraries,
        // but that's a server issue.
        if filters.sortBy.first == SortBy.random.filter {
            parameters.excludeItemIDs = items.compactMap(\.id)
        }

        return parameters
    }
}
