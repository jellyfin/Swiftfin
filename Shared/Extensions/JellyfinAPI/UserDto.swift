//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension UserDto {

    func profileImageSource(
        client: JellyfinClient,
        maxWidth: CGFloat? = nil
    ) -> ImageSource {
        UserState(
            id: id ?? "",
            serverID: "",
            username: ""
        )
        .profileImageSource(
            client: client
        )
    }

    func getFullUser(userSession: UserSession) async throws -> UserDto {
        guard let id else {
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Paths.getUserByID(userID: id)
        let response = try await userSession.client.send(request)

        return response.value
    }
}
