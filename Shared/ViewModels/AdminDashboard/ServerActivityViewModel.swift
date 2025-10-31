//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import IdentifiedCollections
import JellyfinAPI

// TODO: use `ServerUsersLibrary`

final class ServerActivityViewModel: PagingLibraryViewModel<ServerActivityLibrary> {

    private(set) var users: IdentifiedArrayOf<UserDto> = []

    init() {
        super.init(library: .init())

        self.core.addFunction(for: \.refresh) { [weak self] in
            try await self?.getUsers()
        }
    }

    private func getUsers() async throws {
        let request = Paths.getUsers()
        let response = try await userSession.client.send(request)

        self.users = IdentifiedArray(uniqueElements: response.value)
    }
}
