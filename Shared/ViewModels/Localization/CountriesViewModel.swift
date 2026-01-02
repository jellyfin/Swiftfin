//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class CountriesViewModel: BaseFetchViewModel<[CountryInfo]> {

    override func getValue() async throws -> [CountryInfo] {
        let request = Paths.getCountries
        let response = try await userSession.client.send(request)

        return response.value
    }
}
