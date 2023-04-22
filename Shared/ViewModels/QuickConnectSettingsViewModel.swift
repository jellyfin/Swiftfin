//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class QuickConnectSettingsViewModel: ViewModel {

    func authorize(code: String) async throws {
        let request = Paths.authorize(code: code)
        let response = try await userSession.client.send(request)

        let decoder = JSONDecoder()
        let isAuthorized = (try? decoder.decode(Bool.self, from: response.value)) ?? false

        if !isAuthorized {
            throw JellyfinAPIError("Authorization unsuccessful")
        }
    }
}
