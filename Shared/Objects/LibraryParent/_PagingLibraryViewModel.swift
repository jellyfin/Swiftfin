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

@MainActor
@Stateful
class _PagingLibraryViewModel<_PagingLibrary: PagingLibrary>: ViewModel, @preconcurrency Identifiable {

    typealias Element = _PagingLibrary.Element

    @CasePathable
    enum Action {
        case refresh
        case retrieveNextPage
        case retrieveRandomItem

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.refreshing, then: .content)
            case .retrieveNextPage:
                .background(.retrievingNextPage)
            case .retrieveRandomItem:
                .background(.retrievingRandomItem)
            }
        }
    }

    enum BackgroundState {
        case retrievingNextPage
        case retrievingRandomItem
    }

    enum Event {
        case retrievedRandomItem(Element)
    }

    enum State {
        case content
        case error
        case initial
        case refreshing
    }

    @Published
    var grouping: LibraryGrouping? = nil
    @Published
    private(set) var elements: IdentifiedArray<Int, Element>

    private var currentPage = 0
    private var hasNextPage = true

    let library: _PagingLibrary

    var id: String {
        library.id
    }

    init(library: _PagingLibrary) {
        self.grouping = library.parent._groupings?.defaultSelection
        self.library = library
        self.elements = IdentifiedArray(
            [],
            id: \.unwrappedIDHashOrZero,
            uniquingIDsWith: { x, _ in x }
        )

        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        currentPage = -1
        hasNextPage = true

        elements.removeAll()
        try await _retrieveNextPage()
    }

    @Function(\Action.Cases.refresh)
    private func _getQueryFilters() async throws {
        await library.filterViewModel?.getQueryFilters()
    }

    @Function(\Action.Cases.retrieveNextPage)
    private func _retrieveNextPage() async throws {
        guard hasNextPage else { return }

        currentPage += 1

        let pageState = LibraryPageState(
            page: currentPage,
            pageSize: 50,
            userSession: userSession
        )

        let nextPageElements = try await library.retrievePage(
            environment: .init(
                filters: library.filterViewModel?.currentFilters ?? .default,
                grouping: grouping
            ),
            pageState: pageState
        )

        guard !Task.isCancelled else { return }

        hasNextPage = !(nextPageElements.count < 50)

        elements.append(contentsOf: nextPageElements)
    }

    @Function(\Action.Cases.retrieveRandomItem)
    private func _retrieveRandomItem() async throws {

        let pageState = LibraryPageState(
            page: 0,
            pageSize: 0,
            userSession: userSession
        )

        guard let randomItem = try await library.retrieveRandomElement(
            environment: .init(
                filters: library.filterViewModel?.currentFilters ?? .default,
                grouping: grouping
            ),
            pageState: pageState
        ) else {
            return
        }

        guard !Task.isCancelled else { return }

        events.send(.retrievedRandomItem(randomItem))
    }
}
