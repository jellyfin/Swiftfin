//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

struct LibraryGrouping: Displayable, Hashable, Identifiable, Storable {
    let displayTitle: String
    let id: String
}

struct LibraryValueEnvironment {
    let filters: ItemFilterCollection
    let grouping: LibraryGrouping?
}

struct LibraryPageState {
    let page: Int
    let pageSize: Int
    let userSession: UserSession
}

protocol _LibraryParent: Displayable, Identifiable<String?> {

    var libraryType: BaseItemKind? { get }
    var _supportedItemTypes: [BaseItemKind] { get }
    var _isRecursiveCollection: Bool { get }
    var _groupings: [LibraryGrouping]? { get }
}

extension _LibraryParent {

    var _groupings: [LibraryGrouping]? { nil }
}

struct _TitledLibraryParent: _LibraryParent {
    let libraryType: BaseItemKind? = .collectionFolder
    let displayTitle: String
    let id: String?
    let _supportedItemTypes: [BaseItemKind]
    let _isRecursiveCollection: Bool = false
}

protocol PagingLibrary<Element>: Displayable, Identifiable<String> {

    associatedtype Element: Poster
    associatedtype Parent: _LibraryParent

    var parent: Parent { get }
    var pages: Bool { get }

    var filterViewModel: FilterViewModel? { get }

    func retrievePage(
        environment: LibraryValueEnvironment,
        pageState: LibraryPageState
    ) async throws -> [Element]

    func retrieveRandomElement(
        environment: LibraryValueEnvironment,
        pageState: LibraryPageState
    ) async throws -> Element?
}

extension PagingLibrary {

    var filterViewModel: FilterViewModel? { nil }
    var pages: Bool { true }
}

extension BaseItemDto: _LibraryParent {

    var _groupings: [LibraryGrouping]? {
        switch collectionType {
        case .tvshows:
            [
                .init(displayTitle: L10n.episodes, id: "episodes"),
                .init(displayTitle: L10n.series, id: "series"),
            ]
        default: nil
        }
    }

    var _supportedItemTypes: [BaseItemKind] {
        switch self.type {
        case .folder:
            BaseItemKind.supportedCases
                .appending([.folder, .collectionFolder])
        default:
            BaseItemKind.supportedCases
        }
    }

    var _isRecursiveCollection: Bool {
        guard let collectionType, libraryType != .userView else { return true }

        return ![.tvshows, .boxsets].contains(collectionType)
    }
}

struct _StaticLibrary<Element: Poster>: PagingLibrary {

    let elements: [Element]
    let parent: _TitledLibraryParent
    let pages = false

    var displayTitle: String {
        parent.displayTitle
    }

    var id: String {
        parent.id ?? "unknown"
    }

    init(
        title: String,
        id: String,
        elements: [Element]
    ) {
        self.elements = elements
        self.parent = .init(
            displayTitle: title,
            id: id,
            _supportedItemTypes: BaseItemKind.supportedCases
        )
    }

    func retrievePage(
        environment: LibraryValueEnvironment,
        pageState: LibraryPageState
    ) async throws -> [Element] {
        elements
    }

    func retrieveRandomElement(
        environment: LibraryValueEnvironment,
        pageState: LibraryPageState
    ) async throws -> Element? {
        elements.randomElement()
    }
}

struct _PagingItemLibrary<Parent: _LibraryParent>: PagingLibrary {

    typealias Element = BaseItemDto

    var displayTitle: String {
        parent.displayTitle
    }

    var id: String {
        parent.id ?? "unknown"
    }

    let parent: Parent
    let filterViewModel: FilterViewModel?

    init(
        parent: Parent,
        filters: FilterViewModel?
    ) {
        self.parent = parent
        self.filterViewModel = filters
    }

    func retrievePage(
        environment: LibraryValueEnvironment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        let parameters = await attachPage(
            to: attachFilters(
                to: makeBaseItemParameters(),
                using: filterViewModel?.currentFilters ?? .init()
            ),
            page: pageState.page,
            pageSize: pageState.pageSize
        )

        let request = Paths.getItemsByUserID(
            userID: pageState.userSession.user.id,
            parameters: parameters
        )
        let response = try await pageState.userSession.client.send(
            request
        )

        // 1 - only keep collections that hold valid items
        // 2 - if parent is type `folder`, then we are in a folder-view
        //     context so change `collectionFolder` types to `folder`
        //     for better view handling
        let items = (response.value.items ?? [])
            .filter { $0.collectionType?.isSupported ?? true }
            .map { item in
                if parent.libraryType == .folder, item.type == .collectionFolder {
                    return item.mutating(\.type, with: .folder)
                }

                return item
            }

        return items
    }

    private func makeBaseItemParameters() -> Paths.GetItemsByUserIDParameters {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true

        // Default values, expected to be overridden
        // by parent or filters
        parameters.includeItemTypes = BaseItemKind.supportedCases
        parameters.sortOrder = [.ascending]
        parameters.sortBy = [ItemSortBy.name.rawValue]

        /// Recursive should only apply to parents/folders and not to baseItems
        parameters.isRecursive = parent._isRecursiveCollection
        parameters.includeItemTypes = parent._supportedItemTypes

        if let parentID = parent.id {
            switch parent.libraryType {
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
        using filters: ItemFilterCollection
    ) -> Paths.GetItemsByUserIDParameters {

        var parameters = parameters
        parameters.filters = filters.traits.nilIfEmpty
        parameters.genres = filters.genres.map(\.value).nilIfEmpty
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

        // Random sort won't take into account previous items, so
        // manual exclusion is necessary. This could possibly be
        // a performance issue for loading pages after already loading
        // many items, but there's nothing we can do about that.
//        if filters.sortBy.first == ItemSortBy.random {
//            parameters.excludeItemIDs = elements.compactMap(\.id)
//        }

        return parameters
    }

    private func attachPage(
        to parameters: Paths.GetItemsByUserIDParameters,
        page: Int,
        pageSize: Int
    ) -> Paths.GetItemsByUserIDParameters {
        var parameters = parameters
        parameters.limit = pageSize
        parameters.startIndex = page * pageSize
        return parameters
    }

    func retrieveRandomElement(
        environment: LibraryValueEnvironment,
        pageState: LibraryPageState
    ) async throws -> BaseItemDto? {
        var parameters = attachFilters(
            to: makeBaseItemParameters(),
            using: environment.filters
        )

        parameters.limit = 1
        parameters.sortBy = [ItemSortBy.random.rawValue]

        let request = Paths.getItemsByUserID(userID: pageState.userSession.user.id, parameters: parameters)
        let response = try? await pageState.userSession.client.send(request)

        return response?.value.items?.first
    }
}

extension _PagingItemLibrary where Parent == _TitledLibraryParent {

    init(
        title: String,
        id: String,
        filters: FilterViewModel? = nil
    ) {
        self.parent = .init(
            displayTitle: title,
            id: id,
            _supportedItemTypes: BaseItemKind.supportedCases
        )
        self.filterViewModel = filters
    }
}

struct _PagingNextUpLibrary: PagingLibrary {

    typealias Element = BaseItemDto
    typealias Parent = _TitledLibraryParent

    var displayTitle: String {
        parent.displayTitle
    }

    var id: String {
        parent.id ?? "unknown"
    }

    let parent: _TitledLibraryParent

    init() {
        self.parent = _TitledLibraryParent(
            displayTitle: L10n.nextUp,
            id: "next-up",
            _supportedItemTypes: BaseItemKind.allCases
        )
    }

    func retrievePage(
        environment: LibraryValueEnvironment,
        pageState: LibraryPageState
    ) async throws -> [JellyfinAPI.BaseItemDto] {
        let parameters = attachPage(
            to: makeBaseParameters(),
            page: pageState.page,
            pageSize: pageState.pageSize
        )

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }

    private func makeBaseParameters() -> Paths.GetNextUpParameters {
        var parameters = Paths.GetNextUpParameters()

        parameters.enableUserData = true

        let maxNextUp = Defaults[.Customization.Home.maxNextUp]

        if maxNextUp > 0 {
            parameters.nextUpDateCutoff = Date.now.addingTimeInterval(-maxNextUp)
        }

        parameters.enableRewatching = Defaults[.Customization.Home.resumeNextUp]

        return parameters
    }

    private func attachPage(
        to parameters: Paths.GetNextUpParameters,
        page: Int,
        pageSize: Int
    ) -> Paths.GetNextUpParameters {
        var parameters = parameters
        parameters.limit = pageSize
        parameters.startIndex = page * pageSize
        return parameters
    }

    func retrieveRandomElement(
        environment: LibraryValueEnvironment,
        pageState: LibraryPageState
    ) async throws -> JellyfinAPI.BaseItemDto? {
        nil
    }
}
