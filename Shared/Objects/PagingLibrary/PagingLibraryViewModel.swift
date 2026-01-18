//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import IdentifiedCollections
import JellyfinAPI
import SwiftUI

private let DefaultPageSize = 50
private let SmallPageSize = 20

@MainActor
protocol __PagingLibaryViewModel<_PagingLibrary>: AnyObject, Identifiable,
WithRefresh where Environment == _PagingLibrary.Environment {

    associatedtype _PagingLibrary: PagingLibrary
    associatedtype Environment

    var id: String { get }
    var elements: IdentifiedArrayOf<_PagingLibrary.Element> { get set }
    var environment: Environment { get set }
    var library: _PagingLibrary { get }
}

@MainActor
@Stateful(conformances: [WithRefresh.self])
class PagingLibraryViewModel<_PagingLibrary: PagingLibrary>: ViewModel, @MainActor __PagingLibaryViewModel {

    typealias Background = _BackgroundActions
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
                    .whenBackground(.refreshing)
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
        case refreshing
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
    var elements: IdentifiedArrayOf<Element>
    @Published
    var environment: Environment

    private var hasNextPage = true

    let library: _PagingLibrary
    let pageSize: Int

    var id: String {
        library.parent.libraryID
    }

    init(
        library: _PagingLibrary,
        pageSize: Int = DefaultPageSize
    ) {
        self.environment = library.environment ?? .default
        self.library = library
        self.elements = IdentifiedArray(
            [],
            uniquingIDsWith: { x, _ in x }
        )
        self.hasNextPage = library.hasNextPage
        self.pageSize = pageSize

        super.init()

        Notifications[.itemUserDataDidChange]
            .publisher
            .sink { [weak self] userData in
                self?.updateItemUserData(userData)
            }
            .store(in: &cancellables)
    }

    // TODO: somehow make item checks generic?
    private func updateItemUserData(_ userData: UserItemDataDto) {
        guard let itemID = userData.itemID else { return }

        guard let index = (elements as? IdentifiedArrayOf<BaseItemDto>)?.index(id: itemID) else { return }
        guard var item = elements[index] as? BaseItemDto else { return }
        item.userData = userData
        elements[index] = item as! Element
    }

    private func notifyUserDataChanges(in elements: [Element]) {
        for element in elements {
            guard let item = element as? BaseItemDto,
                  let itemID = item.id,
                  let userData = item.userData
            else { continue }

            let shouldNotify = Container.shared.userItemCache()
                .touch(key: itemID, value: userData)

            if shouldNotify {
                Notifications[.itemUserDataDidChange].post(userData)
            }
        }
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        hasNextPage = true
        elements.removeAll()
        try await __actuallyRetrieveNextPage()
    }

    @Function(\Action.Cases.retrieveNextPage)
    private func _retrieveNextPage() async throws {
        guard hasNextPage else { return }
        await self._actuallyRetrieveNextPage()
    }

    @Function(\Action.Cases._actuallyRetrieveNextPage)
    private func __actuallyRetrieveNextPage() async throws {
        guard hasNextPage else { return }

        let pageState = LibraryPageState(
            pageOffset: elements.count,
            pageSize: pageSize,
            userSession: userSession
        )

        let nextPageElements = try await library.retrievePage(
            environment: environment,
            pageState: pageState
        )

        guard !Task.isCancelled else { return }

        notifyUserDataChanges(in: nextPageElements)

        hasNextPage = !(nextPageElements.count < pageSize)

        elements.append(contentsOf: nextPageElements)
    }

    @Function(\Action.Cases.retrieveRandomElement)
    private func _retrieveRandomElement() async throws {

        let randomElement: Element?

        if let withRandomElementLibrary = library as? any WithRandomElementLibrary<Element, Environment> {
            let pageState = LibraryPageState(
                pageOffset: 0,
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
