//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct SpecialFeaturesLibrary: BaseItemKindLibrary {

    let itemID: String
    let libraryItemTypes: [BaseItemKind] = [.video]
    let parent: TitledLibraryParent = .init(displayTitle: L10n.specialFeatures, id: "special-features")

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        let request = Paths.getSpecialFeatures(itemID: itemID)
        let response = try await pageState.userSession.client.send(request)

        return response.value
    }
}
