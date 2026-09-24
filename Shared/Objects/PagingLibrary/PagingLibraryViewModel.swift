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

    @Published
    private(set) var elements: IdentifiedArrayOf<Element>
    @Published
    var environment: Environment {
        didSet {
            guard environment != oldValue else { return }
            generation += 1
            searchGeneration += 1
            pages.removeAll()
            searchPages.removeAll()
            nextOffset = 0
            nextSearchOffset = 0
            hasNextPage = library.hasNextPage
            hasNextSearchPage = false
            resetPageVisibility()
            publishPages()
        }
    }

    @Published
    private(set) var searchElements: IdentifiedArrayOf<Element>
    @Published
    var searchQuery: String = "" {
        didSet {
            guard searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) != oldValue.trimmingCharacters(in: .whitespacesAndNewlines)
            else { return }
            searchGeneration += 1
            hasNextSearchPage = false
            searchPages.removeAll()
            searchSlots.removeAll()
            searchElements.removeAll()
            resetPageVisibility()
        }
    }

    let library: Library
    let pageSize: Int

    /// Content groups delegate scheduled refreshes to their parent so visibility is resolved with the result.
    let contentGroupRefreshRequests = PassthroughSubject<ContentGroupRefresh, Never>()
    private let refreshesAutomatically: Bool

    @Published
    private(set) var slots: [LibraryPageSlot<Element>] = []
    @Published
    private(set) var searchSlots: [LibraryPageSlot<Element>] = []
    @Published
    private(set) var failedPageOffsets: Set<Int> = []

    var maximumLoadedPages: Int?
    private var pages = LibraryPageWindow<Element>()
    private var searchPages = LibraryPageWindow<Element>()
    private var visibleSlots: [Element.ID: Int] = [:]
    private var pageReloads: [Int: Task<Void, Never>] = [:]

    var displayedSlots: [LibraryPageSlot<Element>] {
        isSearchActive ? searchSlots : slots
    }

    private var nextOffset = 0
    private var nextSearchOffset = 0
    private var generation = 0
    private var searchGeneration = 0
    private var isReleased = false

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
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchableLibrary: (any SearchablePagingLibrary<Element, Environment, PageElement>)? {
        library as? any SearchablePagingLibrary<Element, Environment, PageElement>
    }

    init(
        library: Library,
        pageSize: Int = defaultPagingLibraryPageSize,
        refreshesAutomatically: Bool = true,
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
        self.refreshesAutomatically = refreshesAutomatically

        super.init()
        self.userSession = userSession

        userSession?.items.changes
            .sink { [weak self] change in
                guard let self else { return }
                switch change {
                case .updated:
                    self.reconcileMembership()
                    // Server-backed item collections share one invalidation rule. The
                    // server resolves membership and ordering, including unloaded items.
                    if PageElement.self == ItemPatch.self {
                        self.scheduleRefreshForStoreChange()
                    }
                case let .deleted(id):
                    self.removeDeletedItem(withID: id)
                case .invalidated:
                    self.releaseLoadedPages()
                }
            }
            .store(in: &cancellables)

        $searchQuery
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self, !self.isReleased else { return }
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

    private func reconcileMembership() {
        let removed = Set(slots.compactMap { slot in
            slot.element.flatMap { library.includes($0, environment: environment) ? nil : slot.id }
        })
        let searchRemoved = Set(searchSlots.compactMap { slot in
            slot.element.flatMap { library.includes($0, environment: environment) ? nil : slot.id }
        })
        guard !removed.isEmpty || !searchRemoved.isEmpty else { return }
        pages.remove(ids: removed)
        searchPages.remove(ids: searchRemoved)
        publishPages()
        scheduleRefreshForStoreChange()
    }

    private func removeDeletedItem(withID id: String) {
        let removed = Set(slots.compactMap { slot in
            (slot.id as? ItemEntry.ID)?.item.itemID == id ||
                (slot.id as? String) == id || (slot.id as? String?) == id ? slot.id : nil
        })
        let searchRemoved = Set(searchSlots.compactMap { slot in
            (slot.id as? ItemEntry.ID)?.item.itemID == id ||
                (slot.id as? String) == id || (slot.id as? String?) == id ? slot.id : nil
        })
        guard !removed.isEmpty || !searchRemoved.isEmpty else { return }
        pages.remove(ids: removed)
        searchPages.remove(ids: searchRemoved)
        publishPages()
        // Removing a server row shifts later offsets, including evicted pages.
        scheduleRefreshForStoreChange()
    }

    /// Releases membership while detail screens and other collections retain their own records.
    func releaseLoadedPages() {
        generation += 1
        searchGeneration += 1
        isReleased = true
        storeRefreshTask?.cancel()
        storeRefreshTask = nil
        hasPendingStoreRefresh = false
        elements.removeAll()
        searchElements.removeAll()
        pages.removeAll()
        searchPages.removeAll()
        slots.removeAll()
        searchSlots.removeAll()
        resetPageVisibility()
        nextOffset = 0
        nextSearchOffset = 0
        hasNextPage = false
        hasNextSearchPage = false
        cancel()
    }

    func pageDidAppear(_ slot: LibraryPageSlot<Element>) {
        visibleSlots[slot.id] = slot.offset
        guard maximumLoadedPages != nil else { return }
        if slot.element == nil {
            reloadPage(at: slot.offset)
        }
    }

    func pageDidDisappear(_ slot: LibraryPageSlot<Element>) {
        visibleSlots.removeValue(forKey: slot.id)
        let offset = visibleSlots.values.min(by: { abs($0 - slot.offset) < abs($1 - slot.offset) }) ?? slot.offset
        if retainPages(around: offset, isSearch: isSearchActive) {
            publishPages()
        }
    }

    func reloadPage(at offset: Int) {
        let isSearch = isSearchActive
        guard pageReloads[offset] == nil, !isReleased,
              !(isSearch ? searchPages.isLoaded(offset: offset) : pages.isLoaded(offset: offset))
        else { return }
        let query = normalizedSearchQuery
        let requestGeneration = generation
        let requestSearchGeneration = searchGeneration
        failedPageOffsets.remove(offset)
        pageReloads[offset] = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.generation == requestGeneration, self.searchGeneration == requestSearchGeneration {
                    self.pageReloads.removeValue(forKey: offset)
                }
            }
            do {
                let page = try self.pageState(offset: offset, pageSize: self.pageSize)
                let response: [PageElement] = if isSearch, let searchable = self.searchableLibrary {
                    try await searchable.retrieveSearchPage(query: query, environment: self.environment, pageState: page)
                } else {
                    try await self.library.retrievePage(environment: self.environment, pageState: page)
                }
                guard !Task.isCancelled, self.generation == requestGeneration,
                      self.searchGeneration == requestSearchGeneration, !self.isReleased else { return }
                try page.userSession.items.validate(page.itemRequest)
                let elements = try self.materialize(response, pageState: page)
                if isSearch {
                    self.searchPages.store(elements, at: offset)
                } else {
                    self.pages.store(elements, at: offset)
                }
                self.retainPages(around: offset, isSearch: isSearch)
                self.publishPages()
            } catch {
                guard !Task.isCancelled, self.generation == requestGeneration,
                      self.searchGeneration == requestSearchGeneration else { return }
                self.failedPageOffsets.insert(offset)
                self.error = error
            }
        }
    }

    @discardableResult
    private func retainPages(around offset: Int, isSearch: Bool) -> Bool {
        guard let maximumLoadedPages else { return false }
        let visibleOffsets = Set(visibleSlots.values)
        if isSearch {
            return searchPages.retain(around: offset, visibleOffsets: visibleOffsets, limit: maximumLoadedPages)
        } else {
            return pages.retain(around: offset, visibleOffsets: visibleOffsets, limit: maximumLoadedPages)
        }
    }

    private func resetPageVisibility() {
        cancelPageReloads()
        visibleSlots.removeAll()
    }

    private func cancelPageReloads() {
        pageReloads.values.forEach { $0.cancel() }
        pageReloads.removeAll()
        failedPageOffsets.removeAll()
    }

    private func materialize(_ response: [PageElement], pageState: LibraryPageState) throws -> [Element] {
        try library.materialize(response, pageState: pageState).filter { library.includes($0, environment: environment) }
    }

    private func publishPages() {
        slots = pages.slots
        searchSlots = searchPages.slots
        visibleSlots = Dictionary(uniqueKeysWithValues: displayedSlots.compactMap { slot in
            visibleSlots[slot.id].map { _ in (slot.id, slot.offset) }
        })
        elements = IdentifiedArray(uniqueElements: slots.compactMap(\.element))
        searchElements = IdentifiedArray(uniqueElements: searchSlots.compactMap(\.element))
        contentGroupRefreshRequests.send(.resolution)
    }

    private func scheduleRefreshForStoreChange() {
        guard !isReleased else { return }

        hasPendingStoreRefresh = true
        guard storeRefreshTask == nil else { return }

        storeRefreshTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // A response can itself update the store. Keep changes received in flight
            // for the next pass instead of cancelling the request that discovered them.
            while self.hasPendingStoreRefresh {
                let delay = max(0.35, 5 - Date.now.timeIntervalSince(self.lastStoreRefresh))
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled, !self.isReleased else { return }
                self.hasPendingStoreRefresh = false

                if self.refreshesAutomatically {
                    await self.background.refresh()
                    guard !Task.isCancelled else { return }
                    if self.isSearchActive {
                        await self.search(query: self.normalizedSearchQuery)
                    }
                    guard !Task.isCancelled else { return }
                } else {
                    self.contentGroupRefreshRequests.send(.contents)
                }
                self.lastStoreRefresh = Date.now
            }
            self.storeRefreshTask = nil
        }
        .asAnyCancellable()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        generation += 1
        isReleased = false
        hasNextPage = true
        nextOffset = 0
        cancelPageReloads()
        if !StateTask.isBackground {
            visibleSlots.removeAll()
            pages.removeAll()
            publishPages()
        }
        try await loadPage(replacing: true)
    }

    @Function(\Action.Cases.getNextPage)
    private func _getNextPage() async throws {
        guard hasNextPage, !isReleased else { return }
        await _actuallyGetNextPage()
    }

    @Function(\Action.Cases._actuallyGetNextPage)
    private func __actuallyGetNextPage() async throws {
        guard hasNextPage, !isReleased else { return }
        try await loadPage(replacing: false)
    }

    private func loadPage(replacing: Bool) async throws {
        let requestGeneration = generation
        var replacing = replacing
        while !Task.isCancelled, !isReleased {
            let offset = replacing ? 0 : nextOffset
            let page = try pageState(offset: offset, pageSize: pageSize)
            let response = try await library.retrievePage(environment: environment, pageState: page)

            guard !Task.isCancelled, requestGeneration == generation, !isReleased,
                  replacing || offset == nextOffset else { return }
            try page.userSession.items.validate(page.itemRequest)
            let previousCount = replacing ? 0 : slots.count
            let items = try materialize(response, pageState: page)
            let progress = page.progress(returnedCount: response.count)
            nextOffset = progress.nextOffset
            hasNextPage = library.hasNextPage && progress.hasNextPage
            if replacing {
                pages.removeAll()
                replacing = false
            }
            pages.store(items, at: offset)
            retainPages(around: offset, isSearch: false)
            publishPages()
            guard slots.count == previousCount, hasNextPage else { return }
        }
    }

    @Function(\Action.Cases.search)
    private func _search(_ query: String) async throws {
        guard !isReleased else { return }
        nextSearchOffset = 0
        searchPages.removeAll()
        guard query.isNotEmpty,
              searchableLibrary != nil
        else {
            hasNextSearchPage = false
            publishPages()
            return
        }

        searchGeneration += 1
        resetPageVisibility()
        publishPages()
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
        while !Task.isCancelled, !isReleased {
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
                  offset == nextSearchOffset, !isReleased
            else { return }

            try page.userSession.items.validate(page.itemRequest)
            let previousCount = searchSlots.count
            let items = try materialize(response, pageState: page)
            let progress = page.progress(returnedCount: response.count)
            nextSearchOffset = progress.nextOffset
            hasNextSearchPage = progress.hasNextPage
            searchPages.store(items, at: offset)
            retainPages(around: offset, isSearch: true)
            publishPages()
            guard searchSlots.count == previousCount, hasNextSearchPage else { return }
        }
    }

    @Function(\Action.Cases.getRandomItem)
    private func _getRandomItem() async throws {
        let requestGeneration = generation
        let randomElement: Element?
        if let randomLibrary = library as? any WithRandomElementLibrary<Element, Environment, PageElement> {
            let page = try pageState(offset: 0, pageSize: 1)
            let value = try await randomLibrary.retrieveRandomElement(environment: environment, pageState: page)
            guard !Task.isCancelled, requestGeneration == generation, !isReleased else { return }
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
