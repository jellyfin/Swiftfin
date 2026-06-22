//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct ServerUsersLibrary: PagingLibrary {

    let parent = TitledLibraryParent(displayTitle: L10n.users, id: "server-users")

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [UserDto] {
        let request = Paths.getUsers()
        let response = try await pageState.userSession.client.send(request)

        return response.value
    }
}
