//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

struct LibraryPageState {

    let pageOffset: Int
    let pageSize: Int
    let userSession: UserSession
    let elementIDs: [Int]
}

protocol _LibraryParent: Displayable {

    associatedtype Grouping: LibraryGrouping = VoidWithLibraryGrouping

    var groupings: (defaultSelection: Grouping, elements: [Grouping])? { get }
    var libraryID: String { get }
}

extension _LibraryParent where Grouping == VoidWithLibraryGrouping {
    var groupings: (defaultSelection: Grouping, elements: [Grouping])? { nil }
}

protocol WithLibraryGrouping<Grouping> {
    associatedtype Grouping: LibraryGrouping
    var grouping: Grouping? { get set }
}

struct VoidWithLibraryGrouping: LibraryGrouping {
    var displayTitle: String = ""
    var id: String = ""
}

import SwiftUI

protocol PagingLibrary<Element> {

    associatedtype Element: LibraryIdentifiable
    associatedtype Environment: WithDefaultValue = VoidWithDefaultValue
    associatedtype LibraryBody: View = AnyView
    associatedtype Parent: _LibraryParent = _TitledLibraryParent

    /// The initial environment configuration for the library.
    /// This can be used to define a static environment, disallowing
    /// mutating changes to a library's environment.
    var environment: Environment? { get }
    var parent: Parent { get }

    // TODO: rename/refactor to something else
    var pages: Bool { get }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [Element]

    func makeLibraryBody(content: some View) -> LibraryBody

    @MenuContentGroupBuilder
    func menuContent(environment: Binding<Environment>) -> [MenuContentGroup]
}

extension PagingLibrary {

    var environment: Environment? { nil }
    var pages: Bool { true }

    func makeLibraryBody(content: some View) -> AnyView {
        content.eraseToAnyView()
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
