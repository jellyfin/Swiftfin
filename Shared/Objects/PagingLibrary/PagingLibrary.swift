//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LibraryPageState {
    let pageOffset: Int
    let pageSize: Int
    let userSession: UserSession
}

@MainActor
protocol PagingLibrary<Element> {

    associatedtype Element: Identifiable
    associatedtype Environment: WithDefaultValue = Empty
    associatedtype Parent: LibraryParent = TitledLibraryParent

    var environment: Environment? { get }
    var hasNextPage: Bool { get }
    var parent: Parent { get }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [Element]

    @ViewBuilder
    func makeLibraryBody(
        viewModel: PagingLibraryViewModel<Self>,
        @ViewBuilder content: @escaping () -> some View
    ) -> AnyView

    func onItemUserDataChanged(
        viewModel: PagingLibraryViewModel<Self>,
        userData: UserItemDataDto
    )

    func makeFilterViewModel(environment: Environment) -> FilterViewModel?

    func setFilters(
        _ filters: ItemFilterCollection,
        on environment: inout Environment
    )
}

extension PagingLibrary {

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

    func onItemUserDataChanged(
        viewModel: PagingLibraryViewModel<Self>,
        userData: UserItemDataDto
    ) {}

    func makeFilterViewModel(environment: Environment) -> FilterViewModel? {
        nil
    }

    func setFilters(
        _ filters: ItemFilterCollection,
        on environment: inout Environment
    ) {}
}

protocol WithRandomElementLibrary<Element, Environment>: PagingLibrary {

    func retrieveRandomElement(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> Element?
}

protocol SearchablePagingLibrary<Element, Environment>: PagingLibrary {

    func retrieveSearchPage(
        query: String,
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [Element]
}
