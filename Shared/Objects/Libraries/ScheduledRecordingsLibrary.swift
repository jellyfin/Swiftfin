//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

struct ScheduledRecordingsLibrary: BaseItemKindLibrary {

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
            .filter(\.isScheduledRecording)
            .sorted(using: \.startDate)
            .compactMap(\.programInfo)
    }

    func makeLibraryBody(
        viewModel: PagingLibraryViewModel<Self>,
        @ViewBuilder content: @escaping () -> some View
    ) -> AnyView {
        content()
            .onReceive(Notifications[.recordingTimersDidChange].publisher) {
                viewModel.background.refresh()
            }
            .eraseToAnyView()
    }
}
