//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import Get
import JellyfinAPI

extension BaseItemDto {

    func getMediaSegments(userSession: UserSession) async throws -> [MediaSegmentDto] {
        guard let id else {
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Request<MediaSegmentDtoQueryResult>(path: "/MediaSegments/\(id)")
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
