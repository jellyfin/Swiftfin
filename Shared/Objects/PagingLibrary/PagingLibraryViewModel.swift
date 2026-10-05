//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import FactoryKit
import Foundation
import IdentifiedCollections
import JellyfinAPI

let defaultPagingLibraryPageSize = 50

@MainActor
@Stateful(conformances: [WithRefresh.self])
class PagingLibraryViewModel<Library: PagingLibrary>: ViewModel, Identifiable {

    typealias Background = _BackgroundActions
    typealias Element = Library.Element
    typealias PageElement = Library.PageElement
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

    // Collections own their items until they are replaced or this view model is released.
    @Published
    private(set) var elements: IdentifiedArrayOf<Element>
    @Published
    var environment: Environment {
        didSet {
            guard environment != oldValue else { return }

            generation += 1
            searchGeneration += 1
            elements.removeAll()
            searchElements.removeAll()
            nextOffset = 0
            nextSearchOffset = 0
            hasNextPage = library.hasNextPage
            hasNextSearchPage = false
        }
    }

    @Published
    private(set) var searchElements: IdentifiedArrayOf<Element>
    @Published
    var searchQuery: String = "" {
        didSet {
            guard searchQuery.nilIfBlank != oldValue.nilIfBlank
            else { return }

            searchGeneration += 1
            hasNextSearchPage = false
            searchElements.removeAll()
            nextSearchOffset = 0
        }
    }

    let library: Library
    let pageSize: Int

    private var nextOffset = 0
    private var nextSearchOffset = 0
    private var generation = 0
    private var searchGeneration = 0
    private var isInvalidated = false

    private var hasNextPage: Bool
    private var hasNextSearchPage: Bool
    private var storeRefreshTask: AnyCancellable?
    private var hasPendingStoreRefresh = false
    private var lastStoreRefresh = Date.distantPast

    nonisolated let id: String

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
        searchQuery.nilIfBlank ?? ""
    }

    private var searchableLibrary: (any SearchablePagingLibrary<Element, Environment, PageElement>)? {
        library as? any SearchablePagingLibrary<Element, Environment, PageElement>
    }

    init(
        library: Library,
        pageSize: Int = defaultPagingLibraryPageSize,
        userSession: UserSession? = Container.shared.currentUserSession()
    ) {
        self.id = library.parent.pagingLibraryID
        self.elements = IdentifiedArray([], uniquingIDsWith: { existing, _ in existing })
        self.environment = library.environment ?? .default
        self.searchElements = IdentifiedArray([], uniquingIDsWith: { existing, _ in existing })
        self.hasNextPage = library.hasNextPage
        self.hasNextSearchPage = false
        self.library = library
        self.pageSize = pageSize

        super.init()
        self.userSession = userSession

        userSession?.items
            .changes
            .sink { [weak self] change in
                guard let self else { return }

                switch change {
                case let .updated(update):
                    // User data can change membership in other collections.
                    if update.userDataChanged,
                       self.library.shouldRefreshForUserDataChange(environment: self.environment)
                    {
                        self.reconcileMembership(withID: update.itemID)
                        self.scheduleRefreshForStoreChange()
                    }

                case .libraryChanged:
                    self.scheduleRefreshForStoreChange()

                case let .deleted(id):
                    let removed = self.removeElements { self.matchesItemID($0.id, id) }
                    // A deleted row can shift server offsets even when it was never loaded.
                    if removed || self.library.hasNextPage {
                        self.scheduleRefreshForStoreChange()
                    }

                case .invalidated:
                    self.invalidateItems()
                }
            }
            .store(in: &cancellables)

        $searchQuery
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self, !self.isInvalidated else { return }

                self.search(query: query)
            }
            .store(in: &cancellables)
    }

    func refreshForEnvironmentChange() {
        refresh()
        if isSearchActive {
            search(query: normalizedSearchQuery)
        }
    }

    private func reconcileMembership(withID id: String) {
        _ = removeElements { element in
            matchesItemID(element.id, id) && !library.includes(element, environment: environment)
        }
    }

    private func removeElements(where shouldRemove: (Element) -> Bool) -> Bool {
        var removed = false
        if elements.contains(where: shouldRemove) {
            elements.removeAll(where: shouldRemove)
            removed = true
        }
        if searchElements.contains(where: shouldRemove) {
            searchElements.removeAll(where: shouldRemove)
            removed = true
        }
        return removed
    }

    private func matchesItemID(_ elementID: Element.ID, _ itemID: String) -> Bool {
        (elementID as? ItemEntry.ID)?.item.itemID == itemID ||
            (elementID as? String) == itemID || (elementID as? String?) == itemID
    }

    private func invalidateItems() {
        generation += 1
        searchGeneration += 1
        isInvalidated = true
        storeRefreshTask?.cancel()
        storeRefreshTask = nil
        hasPendingStoreRefresh = false
        elements.removeAll()
        searchElements.removeAll()
        nextOffset = 0
        nextSearchOffset = 0
        hasNextPage = false
        hasNextSearchPage = false
        cancel()
    }

    private func materialize(_ response: [PageElement], pageState: LibraryPageState) throws -> [Element] {
        try library.materialize(response, pageState: pageState).filter { library.includes($0, environment: environment) }
    }

    private func scheduleRefreshForStoreChange() {
        guard !isInvalidated else { return }

        hasPendingStoreRefresh = true
        guard storeRefreshTask == nil else { return }

        let delay = max(0.35, 5 - Date.now.timeIntervalSince(lastStoreRefresh))
        storeRefreshTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self, !self.isInvalidated else { return }

            self.hasPendingStoreRefresh = false

            await self.background.refresh()
            guard !Task.isCancelled else { return }

            if self.isSearchActive {
                await self.search(query: self.normalizedSearchQuery)
            }
            guard !Task.isCancelled else { return }

            self.lastStoreRefresh = Date.now
            self.storeRefreshTask = nil

            // Changes received during the request get another pass without retaining this owner while waiting.
            if self.hasPendingStoreRefresh {
                self.scheduleRefreshForStoreChange()
            }
        }
        .asAnyCancellable()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        guard !isInvalidated else { return }

        generation += 1
        hasNextPage = true
        nextOffset = 0
        if !StateTask.isBackground {
            elements.removeAll()
        }
        try await loadPage(replacing: true)
    }

    @Function(\Action.Cases.getNextPage)
    private func _getNextPage() async throws {
        guard hasNextPage, !isInvalidated, !background.is(.refreshing) else { return }

        await _actuallyGetNextPage()
    }

    @Function(\Action.Cases._actuallyGetNextPage)
    private func __actuallyGetNextPage() async throws {
        guard hasNextPage, !isInvalidated, !background.is(.refreshing) else { return }

        try await loadPage(replacing: false)
    }

    private func loadPage(replacing: Bool) async throws {
        let requestGeneration = generation
        var replacing = replacing
        while !Task.isCancelled, !isInvalidated {
            let offset = replacing ? 0 : nextOffset
            let page = try pageState(offset: offset, pageSize: pageSize)
            let response = try await library.retrievePage(environment: environment, pageState: page)

            guard !Task.isCancelled, requestGeneration == generation, !isInvalidated,
                  replacing || offset == nextOffset else { return }

            try page.userSession.items.validate(page.itemRequest)
            let previousCount = replacing ? 0 : elements.count
            let items = try IdentifiedArray(
                materialize(response, pageState: page),
                uniquingIDsWith: { existing, _ in existing }
            )
            let progress = page.progress(returnedCount: response.count)
            nextOffset = progress.nextOffset
            hasNextPage = library.hasNextPage && progress.hasNextPage
            if replacing {
                elements = items
                replacing = false
            } else {
                elements.append(contentsOf: items.filter { elements[id: $0.id] == nil })
            }
            guard elements.count == previousCount, hasNextPage else { return }
        }
    }

    @Function(\Action.Cases.search)
    private func _search(_ query: String) async throws {
        guard !isInvalidated else { return }

        nextSearchOffset = 0
        searchElements.removeAll()
        guard query.isNotEmpty,
              searchableLibrary != nil
        else {
            hasNextSearchPage = false
            return
        }

        searchGeneration += 1
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

        let requestGeneration = searchGeneration
        while !Task.isCancelled, !isInvalidated {
            let offset = nextSearchOffset
            let page = try pageState(offset: offset, pageSize: pageSize)
            let response = try await searchableLibrary.retrieveSearchPage(
                query: query,
                environment: environment,
                pageState: page
            )

            guard !Task.isCancelled,
                  query == normalizedSearchQuery,
                  requestGeneration == searchGeneration,
                  offset == nextSearchOffset, !isInvalidated
            else { return }

            try page.userSession.items.validate(page.itemRequest)
            let previousCount = searchElements.count
            let items = try IdentifiedArray(
                materialize(response, pageState: page),
                uniquingIDsWith: { existing, _ in existing }
            )
            let progress = page.progress(returnedCount: response.count)
            nextSearchOffset = progress.nextOffset
            hasNextSearchPage = progress.hasNextPage
            searchElements.append(contentsOf: items.filter { searchElements[id: $0.id] == nil })
            guard searchElements.count == previousCount, hasNextSearchPage else { return }
        }
    }

    @Function(\Action.Cases.getRandomItem)
    private func _getRandomItem() async throws {
        let requestGeneration = generation
        let randomElement: Element?
        if let randomLibrary = library as? any WithRandomElementLibrary<Element, Environment, PageElement> {
            let page = try pageState(offset: 0, pageSize: 1)
            let value = try await randomLibrary.retrieveRandomElement(environment: environment, pageState: page)
            guard !Task.isCancelled, requestGeneration == generation, !isInvalidated else { return }

            try page.userSession.items.validate(page.itemRequest)
            randomElement = try value.flatMap { try materialize([$0], pageState: page).first }
        } else {
            randomElement = elements.randomElement()
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

extension PagingLibraryViewModel: @MainActor Displayable {

    var displayTitle: String {
        library.parent.displayTitle
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
