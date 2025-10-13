//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct ServerActivityLibrary: PagingLibrary {

    struct Environment: WithDefaultValue {
        var hasUserID: Bool?
        var minDate: Date?

        static var `default`: Self { .init() }
    }

    let parent: _TitledLibraryParent

    init() {
        self.parent = .init(
            displayTitle: L10n.activity,
            libraryID: "server-activity",
        )
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [ActivityLogEntry] {

        var parameters = Paths.GetLogEntriesParameters()
        parameters.hasUserID = environment.hasUserID
        parameters.minDate = environment.minDate

        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset

        let request = Paths.getLogEntries(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
