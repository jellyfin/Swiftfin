//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct StoredFilterEditorView: View {

    @ObservedObject
    var viewModel: FilterViewModel

    @Router
    private var router

    @State
    private var name: String
    @State
    private var isLibraryOnly: Bool

    @StoredValue(.User.savedFilters)
    private var savedFilters

    private let filters: ItemFilterCollection
    private let savedFilter: StoredItemFilter?

    init(viewModel: FilterViewModel, filters: ItemFilterCollection) {
        let savedFilter = viewModel.selectedSavedFilter

        self.viewModel = viewModel
        self.filters = filters
        self.savedFilter = savedFilter
        self._name = State(initialValue: savedFilter?.name ?? "")
        self._isLibraryOnly = State(
            initialValue: savedFilter.map { $0.libraryID != nil || $0.filters.itemTypes.isNotEmpty } ?? true
        )
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var libraryID: String? {
        isLibraryOnly ? viewModel.libraryID : nil
    }

    private var storedFilters: ItemFilterCollection {
        filters.mutating(\.itemTypes, with: isLibraryOnly ? viewModel.libraryItemTypes : [])
    }

    private var isDuplicate: Bool {
        (libraryID == nil ? savedFilters : viewModel.savedFilters).contains {
            $0.id != savedFilter?.id && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }

    var body: some View {
        Form(systemImage: "line.3.horizontal.decrease") {
            Section {
                TextField(L10n.name, text: $name)
            } header: {
                Text(L10n.name)
            } footer: {
                if isDuplicate {
                    Label(L10n.duplicateUserSaved(trimmedName), systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            if viewModel.parent != nil, viewModel.libraryID != nil || viewModel.libraryItemTypes.isNotEmpty {
                Section {
                    Toggle(L10n.limitToLibrary, isOn: $isLibraryOnly)
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
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            let saveAction = {
                if let index = savedFilters.firstIndex(where: { $0.id == savedFilter?.id }) {
                    savedFilters[index].name = trimmedName
                    savedFilters[index].libraryID = libraryID
                    savedFilters[index].filters = storedFilters
                } else {
                    savedFilters.append(
                        StoredItemFilter(
                            libraryID: libraryID,
                            name: trimmedName,
                            filters: storedFilters
                        )
                    )
                }

                Notifications[.savedFiltersDidChange].post()
                router.dismiss()
            }

            Group {
                #if os(iOS)
                if #available(iOS 26, *) {
                    Button(L10n.save, role: .confirm, action: saveAction)
                } else {
                    Button(L10n.save, action: saveAction)
                        .backport
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                }
                #else
                Button(L10n.save, action: saveAction)
                #endif
            }
            .disabled(
                trimmedName.isEmpty ||
                    isDuplicate ||
                    (
                        savedFilter?.name == trimmedName &&
                            savedFilter?.libraryID == libraryID &&
                            savedFilter?.filters == storedFilters
                    )
            )
        }
    }
}
