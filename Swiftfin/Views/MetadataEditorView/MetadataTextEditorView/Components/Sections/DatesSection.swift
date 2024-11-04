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

extension MetadataTextEditorView {
    struct DatesSection: View {
        @Binding
        var item: BaseItemDto

        let itemType: BaseItemKind

        var body: some View {
            Section("Dates") {
                DatePicker("Date Added", selection: Binding(get: {
                    item.dateCreated ?? Date()
                }, set: {
                    item.dateCreated = $0
                }), displayedComponents: .date)

                DatePicker("Release Date", selection: Binding(get: {
                    item.premiereDate ?? Date()
                }, set: {
                    item.premiereDate = $0
                }), displayedComponents: .date)

                if itemType == .series || itemType == .person {
                    DatePicker("End Date", selection: Binding(get: {
                        item.endDate ?? Date()
                    }, set: {
                        item.endDate = $0
                    }), displayedComponents: .date)
                }
            }

            Section("Year") {
                TextField("Year", value: Binding(get: {
                    item.productionYear ?? 0
                }, set: {
                    item.productionYear = $0
                }), formatter: NumberFormatter())
                    .keyboardType(.numberPad)
            }
        }
    }
}
