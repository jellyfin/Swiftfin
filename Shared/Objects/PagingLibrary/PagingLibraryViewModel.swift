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
            case ._actuallyGetNextPage:
                .background(.gettingNextPage)
            }
        }
    }

    enum BackgroundState {
        case refreshing
        case gettingNextPage
        case gettingRandomItem
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
    var elements: IdentifiedArray<Int, Element>
    @Published
    var environment: Environment

    let library: Library
    let pageSize: Int

    private var hasNextPage: Bool

    var id: String? {
        library.parent.id
    }

    init(
        library: Library,
        pageSize: Int = defaultPagingLibraryPageSize
    ) {
        self.elements = IdentifiedArray([], id: \.unwrappedIDHashOrZero, uniquingIDsWith: { existing, _ in existing })
        self.environment = library.environment ?? .default
        self.hasNextPage = library.hasNextPage
        self.library = library
        self.pageSize = pageSize

        super.init()

        Notifications[.didDeleteItem]
            .publisher
            .sink { [weak self] id in
                self?.elements.remove(id: id.hashValue)
            }
            .store(in: &cancellables)
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

    private func pageState(offset: Int, pageSize: Int) -> LibraryPageState {
        .init(
            pageOffset: offset,
            pageSize: pageSize,
            userSession: userSession
        )
    }
}

extension PagingLibraryViewModel: LibraryIdentifiable {

    var unwrappedIDHashOrZero: Int {
        id?.hashValue ?? 0
    }
}
