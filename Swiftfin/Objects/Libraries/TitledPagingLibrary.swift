//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

@MainActor
struct TitledPagingLibrary<Library: PagingLibrary>: PagingLibrary {

    typealias Element = Library.Element
    typealias PageElement = Library.PageElement

    let library: Library
    let parent: TitledLibraryParent

    var environment: Library.Environment? {
        library.environment
    }

    var hasNextPage: Bool {
        library.hasNextPage
    }

    init(
        library: Library,
        displayTitle: String,
        id: String
    ) {
        self.library = library
        self.parent = .init(displayTitle: displayTitle, id: id)
    }

    func retrievePage(
        environment: Library.Environment,
        pageState: LibraryPageState
    ) async throws -> [PageElement] {
        try await library.retrievePage(
            environment: environment,
            pageState: pageState
        )
    }

    func materialize(_ page: [PageElement], pageState: LibraryPageState) throws -> [Element] {
        try library.materialize(page, pageState: pageState)
    }

    func includes(_ element: Element, environment: Library.Environment) -> Bool {
        library.includes(element, environment: environment)
    }

    func shouldRefreshForUserDataChange(environment: Library.Environment) -> Bool {
        library.shouldRefreshForUserDataChange(environment: environment)
    }

    func libraryStyleOptions(
        environment: Library.Environment
    ) -> LibraryStyleOptions {
        library.libraryStyleOptions(environment: environment)
    }
}
