//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct RemoteImageProvidersLibrary: PagingLibrary {

    let hasNextPage: Bool = false
    let parent: _TitledLibraryParent

    // TODO: wrong ids
    init(itemID: String) {
        self.parent = .init(
            displayTitle: "Providers",
            libraryID: itemID
        )
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [ImageProviderInfo] {
        let request = Paths.getRemoteImageProviders(itemID: parent.libraryID)
        let response = try await pageState.userSession.client.send(request)
        return response.value
    }
}
