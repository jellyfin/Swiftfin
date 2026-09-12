//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Get
import JellyfinAPI
import SwiftUI

@MainActor
final class LibraryPageState {
    let pageOffset: Int
    let pageSize: Int
    let userSession: UserSession
    let itemRequest: ItemStore.RequestToken

    init(pageOffset: Int, pageSize: Int, userSession: UserSession) throws {
        self.pageOffset = pageOffset
        self.pageSize = pageSize
        self.userSession = userSession
        self.itemRequest = try userSession.items.beginRequest()
    }

    private var consumedRows: Int?
    private var totalRows: Int?

    func items(from response: Response<BaseItemDtoQueryResult>) throws -> [ItemPatch] {
        consumedRows = response.value.items?.count ?? 0
        totalRows = response.value.totalRecordCount
        return try ItemPatch.items(from: response)
    }

    func items(from response: Response<[BaseItemDto]>) throws -> [ItemPatch] {
        consumedRows = response.value.count
        totalRows = response.value.count
        return try ItemPatch.items(from: response)
    }

    func progress(returnedCount: Int) -> LibraryPageProgress {
        LibraryPageProgress(offset: pageOffset, pageSize: pageSize, consumedRows: consumedRows ?? returnedCount, totalRows: totalRows)
    }
}

@MainActor
protocol PagingLibrary<Element> {

    associatedtype Element: Identifiable
    associatedtype PageElement = Element
    associatedtype Environment: WithDefaultValue = Empty
    associatedtype Parent: LibraryParent = TitledLibraryParent

    var environment: Environment? { get }
    var hasNextPage: Bool { get }
    var parent: Parent { get }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [PageElement]

    func materialize(_ page: [PageElement], pageState: LibraryPageState) throws -> [Element]

    func includes(_ element: Element, environment: Environment) -> Bool

    @ViewBuilder
    func makeLibraryBody(
        viewModel: PagingLibraryViewModel<Self>,
        @ViewBuilder content: @escaping () -> some View
    ) -> AnyView

    func libraryStyleOptions(environment: Environment) -> LibraryStyleOptions

    func makeMenuContent(environment: Binding<Environment>) -> AnyView
}

extension PagingLibrary where Element: LibraryElement {

    func libraryStyleOptions(environment: Environment) -> LibraryStyleOptions {
        Element.supportedLibraryStyleOptions
    }

    func resolvedLibraryStyleOptions(
        environment: Environment,
        elements: some Sequence<Element>
    ) -> LibraryStyleOptions {
        LibraryStyleOptions.resolving(
            elements.map(\.supportedLibraryStyleOptions),
            fallback: libraryStyleOptions(environment: environment)
        )
    }
}

extension PagingLibrary {

    func includes(_ element: Element, environment: Environment) -> Bool {
        true
    }

    var environment: Environment? {
        nil
    }

    var hasNextPage: Bool {
        true
    }

    func makeLibraryBody(
        viewModel: PagingLibraryViewModel<Self>,
        @ViewBuilder content: @escaping () -> some View
    ) -> AnyView {
        content()
            .eraseToAnyView()
    }

    func libraryStyleOptions(environment: Environment) -> LibraryStyleOptions {
        .default
    }

    func makeMenuContent(environment: Binding<Environment>) -> AnyView {
        EmptyView()
            .eraseToAnyView()
    }
}

@MainActor
protocol WithRandomElementLibrary<Element, Environment, PageElement>: PagingLibrary {

    func retrieveRandomElement(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> PageElement?
}

@MainActor
protocol SearchablePagingLibrary<Element, Environment, PageElement>: PagingLibrary {

    func retrieveSearchPage(
        query: String,
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [PageElement]
}

extension PagingLibrary where PageElement == Element {
    func materialize(_ page: [Element], pageState: LibraryPageState) throws -> [Element] {
        page
    }
}
