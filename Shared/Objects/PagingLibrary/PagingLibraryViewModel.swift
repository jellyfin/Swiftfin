//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import IdentifiedCollections
import JellyfinAPI

let defaultPagingLibraryPageSize = 50

@MainActor
@Stateful(conformances: [WithRefresh.self])
class PagingLibraryViewModel<Library: PagingLibrary>: ViewModel, @MainActor Identifiable {

    typealias Background = _BackgroundActions
    typealias Element = Library.Element
    typealias Environment = Library.Environment

    @CasePathable
    enum Action {
        case refresh
        case getNextPage
        case getRandomItem
        case getNextSearchPage
        case search(query: String)

        case _actuallyGetNextPage

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.refreshing, then: .content)
                    .whenBackground(.refreshing)
            case .getNextPage:
                .none
            case .getRandomItem:
                .background(.gettingRandomItem)
            case .getNextSearchPage:
                .background(.gettingNextSearchPage)
            case .search:
                .background(.searching)
                    .onRepeat(.cancel)
            case ._actuallyGetNextPage:
                .background(.gettingNextPage)
            }
        }
    }

    enum BackgroundState {
        case refreshing
        case gettingNextPage
        case gettingRandomItem
        case gettingNextSearchPage
        case searching
    }

    enum Event {
        case gotRandomItem(Element)
    }

    enum State {
        case content
        case error
        case initial
        case refreshing
    }

    @Published
    var elements: IdentifiedArrayOf<Element>
    @Published
    var environment: Environment
    @Published
    var searchElements: IdentifiedArrayOf<Element>
    @Published
    var searchQuery: String = ""

    let library: Library
    let pageSize: Int

    private var hasNextPage: Bool
    private var hasNextSearchPage: Bool
    private var itemUserDataRefreshTask: AnyCancellable?
    private var lastItemUserDataRefresh = Date.distantPast

    var id: String {
        library.parent.pagingLibraryID
    }

    var isSearchActive: Bool {
        normalizedSearchQuery.isNotEmpty
    }

    var isSearchSupported: Bool {
        searchableLibrary != nil
    }

    var displayedElements: IdentifiedArrayOf<Element> {
        isSearchActive ? searchElements : elements
    }

    private var normalizedSearchQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchableLibrary: (any SearchablePagingLibrary<Element, Environment>)? {
        library as? any SearchablePagingLibrary<Element, Environment>
    }

    init(
        library: Library,
        pageSize: Int = defaultPagingLibraryPageSize
    ) {
        self.elements = IdentifiedArray([], uniquingIDsWith: { existing, _ in existing })
        self.environment = library.environment ?? .default
        self.searchElements = IdentifiedArray([], uniquingIDsWith: { existing, _ in existing })
        self.hasNextPage = library.hasNextPage
        self.hasNextSearchPage = false
        self.library = library
        self.pageSize = pageSize

        super.init()

        Notifications[.didDeleteItem]
            .publisher
            .sink { [weak self] id in
                self?.removeDeletedItem(withID: id)
            }
            .store(in: &cancellables)

        Notifications[.itemUserDataDidChange]
            .publisher
            .sink { [weak self] userData in
                guard let self else { return }

                updateItemUserData(userData)
                library.onItemUserDataChanged(viewModel: self, userData: userData)
            }
            .store(in: &cancellables)

        $searchQuery
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.search(query: query)
            }
            .store(in: &cancellables)
    }

    func refreshForEnvironmentChange() {
        if isSearchActive {
            search(query: normalizedSearchQuery)
        } else {
            refresh()
        }
    }

    private func removeDeletedItem(withID id: String) {
        removeDeletedItem(withID: id, from: &elements)
        removeDeletedItem(withID: id, from: &searchElements)
    }

    private func removeDeletedItem(
        withID id: String,
        from elements: inout IdentifiedArrayOf<Element>
    ) {
        elements.removeAll { element in
            if let item = element as? BaseItemDto {
                return item.id == id
            }

            if let user = element as? UserDto {
                return user.id == id
            }

            if let elementID = element.id as? String {
                return elementID == id
            }

            if let elementID = element.id as? String? {
                return elementID == id
            }

            return false
        }
    }

    private func updateItemUserData(_ userData: UserItemDataDto) {
        updateItemUserData(userData, in: &elements)
        updateItemUserData(userData, in: &searchElements)
    }

    private func updateItemUserData(
        _ userData: UserItemDataDto,
        in elements: inout IdentifiedArrayOf<Element>
    ) {
        guard let itemID = userData.itemID else { return }

        for index in elements.indices {
            guard var item = elements[index] as? BaseItemDto,
                  item.id == itemID
            else { continue }

            item.userData = userData
            elements[index] = item as! Element
            return
        }
    }

    func scheduleRefreshForItemUserData(
        debounce: TimeInterval = 0.35,
        minimumInterval: TimeInterval = 5
    ) {
        guard Date.now.timeIntervalSince(lastItemUserDataRefresh) >= minimumInterval else {
            return
        }

        itemUserDataRefreshTask?.cancel()
        itemUserDataRefreshTask = Task { @MainActor [weak self] in
            guard let self else { return }

            if debounce > 0 {
                try? await Task.sleep(for: .seconds(debounce))
            }

            guard !Task.isCancelled else { return }

            await self.background.refresh()
            self.lastItemUserDataRefresh = Date.now
            self.itemUserDataRefreshTask = nil
        }
        .asAnyCancellable()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        hasNextPage = true
        elements.removeAll()
        try await __actuallyGetNextPage()
    }

    @Function(\Action.Cases.getNextPage)
    private func _getNextPage() async throws {
        guard hasNextPage else { return }
        await _actuallyGetNextPage()
    }

    @Function(\Action.Cases._actuallyGetNextPage)
    private func __actuallyGetNextPage() async throws {
        guard hasNextPage else { return }

        let nextPageElements = try await library.retrievePage(
            environment: environment,
            pageState: pageState(offset: elements.count, pageSize: pageSize)
        )

        guard !Task.isCancelled else { return }

        hasNextPage = !(nextPageElements.count < pageSize)
        elements.append(contentsOf: nextPageElements)
    }

    @Function(\Action.Cases.search)
    private func _search(_ query: String) async throws {
        guard query.isNotEmpty,
              searchableLibrary != nil
        else {
            hasNextSearchPage = false
            searchElements.removeAll()
            return
        }

        searchElements.removeAll()
        hasNextSearchPage = true
        try await retrieveNextSearchPage(query: query)
    }

    @Function(\Action.Cases.getNextSearchPage)
    private func _getNextSearchPage() async throws {
        guard isSearchActive,
              hasNextSearchPage,
              !background.is(.searching)
        else { return }

        try await retrieveNextSearchPage(query: normalizedSearchQuery)
    }

    private func retrieveNextSearchPage(query: String) async throws {
        guard let searchableLibrary,
              hasNextSearchPage
        else { return }

        let nextPageElements = try await searchableLibrary.retrieveSearchPage(
            query: query,
            environment: environment,
            pageState: pageState(offset: searchElements.count, pageSize: pageSize)
        )

        guard !Task.isCancelled,
              query == normalizedSearchQuery
        else { return }

        hasNextSearchPage = !(nextPageElements.count < pageSize)
        searchElements.append(contentsOf: nextPageElements)
    }

    @Function(\Action.Cases.getRandomItem)
    private func _getRandomItem() async throws {
        let randomElement: Element? = if let randomLibrary = library as? any WithRandomElementLibrary<Element, Environment> {
            try await randomLibrary.retrieveRandomElement(
                environment: environment,
                pageState: pageState(offset: 0, pageSize: 1)
            )
        } else {
            elements.randomElement()
        }

        guard !Task.isCancelled, let randomElement else { return }

        events.send(.gotRandomItem(randomElement))
    }

    private func pageState(offset: Int, pageSize: Int) throws -> LibraryPageState {
        try .init(
            pageOffset: offset,
            pageSize: pageSize,
            userSession: requireUserSession()
        )
    }
}

extension PagingLibraryViewModel where Element: LibraryElement {

    var libraryStyleOptions: LibraryStyleOptions {
        library.resolvedLibraryStyleOptions(
            environment: environment,
            elements: displayedElements
        )
    }
}
