//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

extension EditMetadataView {
    struct DateSection: View {
        @Binding
        var item: BaseItemDto

        let itemType: BaseItemKind

        var body: some View {
            Section(L10n.dates) {
                DatePicker(L10n.dateAdded, selection: Binding(get: {
                    item.dateCreated ?? Date()
                }, set: {
                    item.dateCreated = $0
                }), displayedComponents: .date)

                DatePicker(itemType == .person ? L10n.birthday : L10n.releaseDate, selection: Binding(get: {
                    item.premiereDate ?? Date()
                }, set: {
                    item.premiereDate = $0
                }), displayedComponents: .date)

                if itemType == .series || itemType == .person {
                    DatePicker(itemType == .person ? L10n.dateOfDeath : L10n.endDate, selection: Binding(get: {
                        item.endDate ?? Date()
                    }, set: {
                        item.endDate = $0
                    }), displayedComponents: .date)
                }
            }

            Section(L10n.year) {
                TextField(itemType == .person ? L10n.birthYear : L10n.year, value: Binding(get: {
                    item.productionYear ?? 0
                }, set: {
                    item.productionYear = $0
                }), formatter: NumberFormatter())
                    .keyboardType(.numberPad)
            }
        }
    }
}
