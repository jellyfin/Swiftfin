//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

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
    associatedtype Parent: _LibraryParent = _TitledLibraryParent

    /// The initial environment configuration for the library.
    /// This can be used to define a static environment, disallowing
    /// mutating changes to a library's environment.
    var environment: Environment? { get }
    var parent: Parent { get }

    var hasNextPage: Bool { get }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [Element]

    @ViewBuilder
    func makeLibraryBody(
        viewModel: PagingLibraryViewModel<Self>,
        @ViewBuilder content: @escaping () -> some View
    ) -> AnyView

    @MenuContentGroupBuilder
    func menuContent(environment: Binding<Environment>) -> [MenuContentGroup]
}

extension PagingLibrary {

    var environment: Environment? { nil }
    var hasNextPage: Bool { true }

    func makeLibraryBody(
        viewModel: PagingLibraryViewModel<Self>,
        @ViewBuilder content: @escaping () -> some View
    ) -> AnyView {
        content()
            .eraseToAnyView()
    }

    @MenuContentGroupBuilder
    func menuContent(environment: Binding<Environment>) -> [MenuContentGroup] {}
}

protocol WithRandomElementLibrary<Element, Environment>: PagingLibrary {

    func retrieveRandomElement(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> Element?
}
