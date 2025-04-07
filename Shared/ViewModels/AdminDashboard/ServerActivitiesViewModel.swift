//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class ServerActivitiesViewModel: PagingLibraryViewModel<ActivityLogEntry> {

    @Published
    var hasUserId: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.send(.refresh)
            }
        }
    }

    @Published
    var minDate: Date? {
        didSet {
            DispatchQueue.main.async {
                self.send(.refresh)
            }
        }
    }

    override func get(page: Int) async throws -> [ActivityLogEntry] {
        var parameters = Paths.GetLogEntriesParameters()
        parameters.limit = pageSize
        parameters.hasUserID = hasUserId
        parameters.minDate = minDate
        parameters.startIndex = page * pageSize

        let request = Paths.getLogEntries(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
