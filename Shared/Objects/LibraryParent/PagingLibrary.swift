//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

protocol PagingLibrary<Element> {

    associatedtype Environment = Void
    associatedtype Element: LibraryIdentifiable
    associatedtype Parent: _LibraryParent = _TitledLibraryParent

    var environment: Environment { get }
    var parent: Parent { get }

    // TODO: rename/refactor to something else
    var pages: Bool { get }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [Element]
}

extension PagingLibrary {
    var pages: Bool { true }
}

extension PagingLibrary where Environment == Void {
    var environment: Void { () }
}

extension PagingLibrary where Environment: WithDefaultValue {
    var environment: Environment { .default }
}
