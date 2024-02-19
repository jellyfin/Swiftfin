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
final class LibraryViewModel: PagingLibraryViewModel, Stateful {

    // MARK: Action

    enum Action {
        case cancel
        case error(JellyfinAPIError)
        case refresh
        case getNextPage
        case getRandomItem
    }

    // MARK: State

    enum State: Equatable {
        case error(JellyfinAPIError)
        case gettingNextPage
        case gettingRandomItem
        case items
        case refreshing
    }

    // MARK: properties

    @Published
    var state: State = .refreshing

    let filterViewModel: FilterViewModel

    let parent: (any LibraryParent)?
    private let saveFilters: Bool
    private var pagingTask: AnyCancellable?
    private var randomItemTask: AnyCancellable?

    var libraryCoordinatorParameters: LibraryCoordinator.Parameters {
        if let parent = parent {
            return .init(parent: parent, filters: filterViewModel.currentFilters)
        } else {
            return .init(filters: filterViewModel.currentFilters)
        }
    }

    // MARK: init

    init(
        parent: (any LibraryParent)? = nil,
        filters: ItemFilters = .init(),
        saveFilters: Bool = false
    ) {
        self.parent = parent
        self.filterViewModel = .init(parent: parent, currentFilters: filters)
        self.saveFilters = saveFilters
        super.init()

        Task {
            await filterViewModel.getGenres()
        }
        .asAnyCancellable()
        .store(in: &cancellables)

        filterViewModel.$currentFilters
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] newFilters in
                guard let self = self, filterViewModel.currentFilters != newFilters else { return }

                print("got new filters")

                if saveFilters, let id = parent?.id {
                    Defaults[.libraryFilterStore][id] = newFilters
                }

                Task { @MainActor in
                    self.send(.refresh)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: respond

    @MainActor
    func respond(to action: Action) -> State {
        switch action {
        case .cancel:

            pagingTask?.cancel()
            randomItemTask?.cancel()

            return .refreshing
        case let .error(error):
            return .error(error)
        case .refresh:

            print("refreshing")

            pagingTask?.cancel()
            randomItemTask?.cancel()

            pagingTask = Task { [weak self] in
                do {
                    // Suspension points cause references to the object. (AsyncSlab)
                    // Meaning many `LibraryViewModel's can be retained in the
                    // background even though the View is gone and handled its release.
                    // That's okay though since mechanisms throughout the app should
                    // handle whether the server can't be connected to/is too slow.
                    try await self?.refresh()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self?.state = .items
                    }
                } catch {

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self?.send(.error(JellyfinAPIError(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .refreshing
        case .getNextPage:

            pagingTask = Task { [weak self] in
                do {
                    try await self?.getNextPage()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self?.state = .items
                    }
                } catch {

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self?.state = .error(JellyfinAPIError(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .gettingNextPage
        case .getRandomItem:
            return .gettingRandomItem
        }
    }

    // MARK: get

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

    private func getItemParameters(for page: Int) -> Paths.GetItemsByUserIDParameters {

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
                includeItemTypes = [.movie, .series, .boxSet]
            case .folder, .userView:
                libraryID = id
                isRecursive = nil
                includeItemTypes = [.movie, .series, .boxSet, .folder, .collectionFolder]
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
        // a performance issue for loading pages when one has already
        // loaded many items, but there's nothing we can do about that.
        if filters.sortBy.first == SortBy.random.filter {
            parameters.excludeItemIDs = items.compactMap(\.id)
        }

        return parameters
    }

    // MARK: getRandomItem

    func getRandomItem() async -> BaseItemDto? {

        var parameters = getItemParameters(for: 0)
        parameters.startIndex = nil
        parameters.limit = 1
        parameters.sortBy = [SortBy.random.rawValue]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try? await userSession.client.send(request)

        return response?.value.items?.first
    }
}
