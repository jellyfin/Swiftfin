//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Get
import JellyfinAPI
import OrderedCollections
import UIKit

// TODO: frankly this is just generic because we also view `BaseItemPerson` elements
//       and I don't want additional views for it. Is there a way we can transform a
//       `BaseItemPerson` into a `BaseItemDto` and just use the concrete type?

// TODO: how to indicate that this is performing some kind of background action (ie: RandomItem)
//       *without* being in an explicit state?
class PagingLibraryViewModel<Element: Poster>: LibraryViewModel<Element>, Eventful, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case cancel
        case error(LibraryError)
        case refresh
        case getNextPage
        case getRandomItem
    }

    enum Event: Equatable {
        case gotRandomItem(Element)
    }

    // MARK: State

    enum State: Equatable {
        case error(LibraryError)
        case gettingNextPage
        case content
        case refreshing
    }

    // TODO: wrap Get HTTP and NSURL errors either here
    //       or in a general implementation
    enum LibraryError: LocalizedError {
        case unableToGetPage
        case unableToGetRandomItem

        var errorDescription: String? {
            switch self {
            case .unableToGetPage:
                "Unable to get page"
            case .unableToGetRandomItem:
                "Unable to get random item"
            }
        }
    }

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    @Published
    final var state: State = .refreshing

    private(set) final var currentPage = 0
    private(set) final var hasNextPage = true

    private var eventSubject: PassthroughSubject<Event, Never> = .init()
    private var isStatic: Bool

    // tasks

    private var pagingTask: AnyCancellable?
    private var randomItemTask: AnyCancellable?

    override init(_ data: some Collection<Element>, parent: (any LibraryParent)? = nil) {
        isStatic = true
        hasNextPage = false
        super.init(data, parent: parent)
    }

    init(parent: (any LibraryParent)? = nil) {
        isStatic = false
        super.init([], parent: parent)
    }

    // MARK: respond

    @MainActor
    func respond(to action: Action) -> State {

        if action == .refresh, isStatic {
            return .content
        }

        switch action {
        case .cancel:

            pagingTask?.cancel()
            randomItemTask?.cancel()

            return .refreshing
        case let .error(error):
            return .error(error)
        case .refresh:

            print("refreshing")

//            filterQueryTask?.cancel()
            pagingTask?.cancel()
            randomItemTask?.cancel()

//            filterQueryTask = Task {
//                await filterViewModel.setQueryFilters()
//            }
//            .asAnyCancellable()

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
                        self?.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self?.send(.error(.unableToGetPage))
                    }
                }
            }
            .asAnyCancellable()

            return .refreshing
        case .getNextPage:

            guard hasNextPage else { return .content }

            pagingTask = Task { [weak self] in
                do {
                    try await self?.getNextPage()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self?.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self?.state = .error(.unableToGetPage)
                    }
                }
            }
            .asAnyCancellable()

            return .gettingNextPage
        case .getRandomItem:

            randomItemTask = Task { [weak self] in
                do {
                    guard let randomItem = try await self?.getRandomItem() else { return }

                    guard !Task.isCancelled else { return }

                    self?.eventSubject.send(.gotRandomItem(randomItem))
                } catch {
                    // TODO: when a general toasting mechanism is implemented, add
                    //       background errors for errors from other background tasks
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    final func refresh() async throws {

        currentPage = -1
        hasNextPage = true

        await MainActor.run {
            items.removeAll()
        }

        try await getNextPage()
    }

    /// Gets the next page of items or immediately returns if
    /// there is not a next page.
    ///
    /// See `get(page:)` for the conditions that determine
    /// if there is a next page or not.
    final func getNextPage() async throws {
        guard hasNextPage else { return }

        currentPage += 1

        let pageItems = try await get(page: currentPage)

        hasNextPage = !(pageItems.count < DefaultPageSize)

        // Sometimes, a subclass may return a page even if it's contextually
        // "out of pages". Check explicitly if items were duplicated.
        let preItemCount = items.count

        await MainActor.run {
            items.append(contentsOf: pageItems)
        }

        print("increased item size by: \(items.count - preItemCount)")
    }

    /// Gets the items at the given page. If the number of items
    /// is less than `DefaultPageSize`, then it is inferred that
    /// there is not a next page and subsequent calls to `getNextPage`
    /// will immediately return.
    func get(page: Int) async throws -> [Element] {
        []
    }
}
