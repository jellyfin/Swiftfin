//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import IdentifiedCollections
import SwiftUI

/// Magic number for page sizes
private let DefaultPageSize = 50

@MainActor
protocol RefreshableViewModel {

    func refresh()
    func refresh() async throws
}

@MainActor
protocol __PagingLibaryViewModel: Identifiable, RefreshableViewModel {

    associatedtype _PagingLibrary: PagingLibrary

    var elements: IdentifiedArray<Int, _PagingLibrary.Element> { get set }
    var id: String { get }
    var library: _PagingLibrary { get }
}

@MainActor
@Stateful
class PagingLibraryViewModel<_PagingLibrary: PagingLibrary>: ViewModel, __PagingLibaryViewModel {

    typealias Element = _PagingLibrary.Element
    typealias Environment = _PagingLibrary.Environment

    @CasePathable
    enum Action {
        case refresh
        case retrieveNextPage
        case retrieveRandomElement

        case _actuallyRetrieveNextPage

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.refreshing, then: .content)
            case .retrieveNextPage:
                .none
            case ._actuallyRetrieveNextPage:
                .background(.retrievingNextPage)
            case .retrieveRandomElement:
                .background(.retrievingRandomElement)
            }
        }
    }

    enum BackgroundState {
        case retrievingNextPage
        case retrievingRandomElement
    }

    enum Event {
        case retrievedRandomElement(Element)
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

    private var currentPage = 0
    private var hasNextPage = true

    let library: _PagingLibrary

    var id: String {
        library.parent.libraryID
    }

    init(library: _PagingLibrary) {
        self.environment = library.environment
        self.library = library
        self.elements = IdentifiedArray(
            [],
            id: \.unwrappedIDHashOrZero,
            uniquingIDsWith: { x, _ in x }
        )
        self.hasNextPage = library.pages

        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        currentPage = -1
        hasNextPage = true

        elements.removeAll()
        try await __actuallyRetrieveNextPage()
    }

    @Function(\Action.Cases.retrieveNextPage)
    private func _retrieveNextPage() async throws {
        guard hasNextPage else { return }
        try await self._actuallyRetrieveNextPage()
    }

    @Function(\Action.Cases._actuallyRetrieveNextPage)
    private func __actuallyRetrieveNextPage() async throws {
        guard hasNextPage else { return }

        currentPage += 1

        let pageState = LibraryPageState(
            page: currentPage,
            pageSize: DefaultPageSize,
            userSession: userSession
        )

        let nextPageElements = try await library.retrievePage(
            environment: environment,
            pageState: pageState
        )

        guard !Task.isCancelled else { return }

        hasNextPage = !(nextPageElements.count < DefaultPageSize)

        elements.append(contentsOf: nextPageElements)
    }

    @Function(\Action.Cases.retrieveRandomElement)
    private func _retrieveRandomElement() async throws {

        let randomElement: Element?

        if let withRandomElementLibrary = library as? any WithRandomElementLibrary<Element, Environment> {
            let pageState = LibraryPageState(
                page: 0,
                pageSize: 0,
                userSession: userSession
            )

            func inner(
                _ _library: some WithRandomElementLibrary<Element, Environment>
            ) async throws -> Element? {
                try await _library.retrieveRandomElement(
                    environment: environment,
                    pageState: pageState
                )
            }

            randomElement = try await inner(withRandomElementLibrary)
        } else {
            randomElement = elements.randomElement()
        }

        guard !Task.isCancelled, let randomElement else { return }

        events.send(.retrievedRandomElement(randomElement))
    }
}
