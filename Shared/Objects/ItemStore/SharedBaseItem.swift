//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import Foundation
import JellyfinAPI

typealias SharedBaseItem = SharedElement<ItemEntry>
typealias OptionalSharedBaseItem = OptionalSharedElement<ItemEntry>
typealias SharedBaseItems = SharedCollection<ItemEntry>

extension ItemEntry: SharedHandle {

    static func resolve(_ value: BaseItemDto) -> ItemEntry {
        let store = Container.shared.currentUserSession()?.items

        // Values without a session or usable ID are only for presentation
        let record = (try? store?.record(for: value)) ?? ItemRecord(
            id: value.id ?? UUID().uuidString,
            presentationValue: value
        )

        return ItemEntry(item: record, occurrence: value.playlistItemID)
    }
}

extension SharedElement where Handle == ItemEntry {

    var entry: ItemEntry {
        projectedValue
    }
}
