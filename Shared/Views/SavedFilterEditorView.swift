//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SavedFilterEditorView: View {

    @ObservedObject
    var viewModel: FilterViewModel

    @Router
    private var router

    @State
    var name: String

    @StoredValue(.User.savedFilters)
    private var savedFilters

    let savedFilter: SavedItemFilter?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicate: Bool {
        viewModel.savedFilters.contains {
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
            Button(L10n.save) {
                if let index = savedFilters.firstIndex(where: { $0.id == savedFilter?.id }) {
                    savedFilters[index].name = trimmedName
                } else {
                    savedFilters.append(
                        SavedItemFilter(
                            libraryID: viewModel.parent?.pagingLibraryID,
                            name: trimmedName,
                            filters: viewModel.staticFilters
                                .union(viewModel.currentFilters)
                                .mutating(\.query, with: nil)
                        )
                    )
                }

                Notifications[.savedFiltersDidChange].post()
                router.dismiss()
            }
            .disabled(trimmedName.isEmpty || isDuplicate || savedFilter?.name == trimmedName)
        }
    }
}
