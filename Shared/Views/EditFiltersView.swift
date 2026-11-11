//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EditFiltersView: View {

    @FocusState
    private var isNameFocused: Bool

    @Router
    private var router

    @State
    private var name: String

    @StoredValue(.User.savedFilters)
    private var savedFilters

    private let filters: ItemFilterCollection
    private let savedFilter: StoredItemFilter?
    private let onSave: ((StoredItemFilter) -> Void)?

    init(
        filters: ItemFilterCollection,
        savedFilter: StoredItemFilter? = nil,
        onSave: ((StoredItemFilter) -> Void)? = nil
    ) {
        self.filters = filters
        self.savedFilter = savedFilter
        self.onSave = onSave
        self._name = State(initialValue: savedFilter?.name ?? "")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicate: Bool {
        savedFilters.contains {
            $0.id != savedFilter?.id &&
                $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }

    private func save() {
        var updatedFilters = savedFilters
        let filter: StoredItemFilter

        if let index = updatedFilters.firstIndex(where: { $0.id == savedFilter?.id }) {
            updatedFilters[index].name = trimmedName
            updatedFilters[index].filters = filters
            filter = updatedFilters[index]
        } else {
            filter = StoredItemFilter(name: trimmedName, filters: filters)
            updatedFilters.append(filter)
        }

        savedFilters = updatedFilters
        Notifications[.savedFiltersDidChange].post()
        onSave?(filter)
        router.dismiss()
    }

    @ContentBuilder
    var body: some View {
        Form(systemImage: "line.3.horizontal.decrease") {
            Section {
                TextField(L10n.name, text: $name)
                    .focused($isNameFocused)
                    #if os(tvOS)
                    .listRowInsets(.zero)
                    #endif
            } header: {
                Text(L10n.name)
            } footer: {
                if isDuplicate {
                    Label(L10n.duplicateUserSaved(trimmedName), systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            Section(L10n.filters) {
                ForEach(ItemFilterType.allCases) { type in
                    ForEach(type.group) { group in
                        let selection = filters[keyPath: group.keyPath]

                        if selection.isNotEmpty {
                            LabeledContent(group.displayTitle) {
                                Text(selection.map(\.displayTitle).joined(separator: ", "))
                                    .multilineTextAlignment(.trailing)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .labeledContentStyle(.focusable)
                        }
                    }
                }
            }

            if let savedFilter {
                Section {
                    Button(L10n.delete, role: .destructive) {
                        savedFilters.removeAll { $0.id == savedFilter.id }
                        Notifications[.savedFiltersDidChange].post()
                        router.dismiss()
                    }
                }
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.savedFilter.localizedCapitalized)
        .onFirstAppear {
            isNameFocused = true
        }
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            Group {
                #if os(iOS)
                if #available(iOS 26, *) {
                    Button(L10n.save, role: .confirm, action: save)
                } else {
                    Button(L10n.save, action: save)
                        .backport
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                }
                #else
                Button(L10n.save, action: save)
                #endif
            }
            .disabled(
                trimmedName.isEmpty ||
                    isDuplicate ||
                    (
                        savedFilter?.name == trimmedName &&
                            savedFilter?.filters == filters
                    )
            )
        }
    }
}
