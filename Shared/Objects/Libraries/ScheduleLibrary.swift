//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ScheduleLibrary: BaseItemKindLibrary {

    let libraryItemTypes: [BaseItemKind] = [.program]
    let parent: TitledLibraryParent = .init(
        displayTitle: L10n.schedule,
        id: "schedule"
    )

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        guard pageState.pageOffset == 0 else { return [] }

        let request = Paths.getTimers()
        let response = try await pageState.userSession.client.send(request)

        return (response.value.items ?? [])
            .filter { timer in
                if let endDate = timer.endDate, endDate <= Date() {
                    return false
                }

                switch timer.status {
                case .cancelled, .completed, .error:
                    return false
                default:
                    return true
                }
            }
            .sorted(using: \.startDate)
            .compactMap(\.programInfo)
    }

    func onTimersChanged(viewModel: PagingLibraryViewModel<ScheduleLibrary>) {
        viewModel.background.refresh()
    }
}
