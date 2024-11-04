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
    struct BaseItemSection: View {
        @Binding
        var item: BaseItemDto
        let itemType: BaseItemKind

        var body: some View {
            Section("File Path") {
                Text(item.path ?? L10n.unknown)
            }

            Section("Title") {
                TextField("Title", text: Binding(get: {
                    item.name ?? ""
                }, set: {
                    item.name = $0
                }))
            }

            Section("Original Title") {
                TextField("Original Title", text: Binding(get: {
                    item.originalTitle ?? ""
                }, set: {
                    item.originalTitle = $0
                }))
            }

            Section("Sort Title") {
                TextField("Title", text: Binding(get: {
                    item.forcedSortName ?? ""
                }, set: {
                    item.forcedSortName = $0
                }))
            }

            Section("Overview") {
                TextEditor(text: Binding(get: {
                    item.overview ?? ""
                }, set: {
                    item.overview = $0
                }))
                .frame(minHeight: 100)
            }

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

            Section("Reviews") {
                ChevronAlertButton(
                    "Critics",
                    subtitle: item.criticRating.map { "\($0)" } ?? .emptyDash,
                    description: "Critics rating out of 10"
                ) {
                    TextField(
                        "Rating",
                        value: $item.criticRating,
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .onChange(of: item.criticRating) { _ in
                        if let rating = item.criticRating {
                            item.criticRating = min(max(rating, 0), 10)
                        }
                    }
                }

                ChevronAlertButton(
                    "Community",
                    subtitle: item.communityRating.map { "\($0)" } ?? .emptyDash,
                    description: "Community rating out of 10"
                ) {
                    TextField(
                        "Rating",
                        value: $item.communityRating,
                        format: .number.precision(.fractionLength(1))
                    )
                    .keyboardType(.decimalPad)
                    .onChange(of: item.communityRating) { _ in
                        if let rating = item.communityRating {
                            item.communityRating = min(max(rating, 0), 10)
                        }
                    }
                }
            }

            Section(L10n.genres) {
                EditableListView(
                    title: "Genre",
                    items: Binding(
                        get: { item.genres ?? [] },
                        set: { item.genres = $0 }
                    )
                )
            }

            Section(L10n.tags) {
                EditableListView(
                    title: "Tag",
                    items: Binding(
                        get: { item.tags ?? [] },
                        set: { item.tags = $0 }
                    )
                )
            }
        }
    }
}
