//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct SavedFilterEditorView: View {

    #if os(tvOS)
    typealias PlatformPicker = ListRowMenu
    #else
    typealias PlatformPicker = Picker
    #endif

    @Default(.Customization.Home.pinnedFilters)
    private var pinnedFilters

    @ObservedObject
    var viewModel: FilterViewModel

    @Router
    private var router

    @State
    var name: String
    @State
    var grouping: BaseItemDto.Grouping?
    @State
    var posterDisplayType: PosterDisplayType
    @State
    var isPinned: Bool

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

            if viewModel.parent != nil {
                Section(L10n.home) {
                    Toggle(L10n.addToHome, isOn: $isPinned)

                    if let groupings = (viewModel.parent as? BaseItemDto)?.groupings {
                        Picker(L10n.defaultGrouping, sources: groupings.elements, selection: $grouping)
                    }

                    PlatformPicker(L10n.defaultPosters, selection: $posterDisplayType)
                }
            }

            if let savedFilter {
                Section {
                    Button(L10n.delete, role: .destructive) {
                        viewModel.savedFilters.removeAll { $0.id == savedFilter.id }
                        pinnedFilters.removeAll { $0 == savedFilter.id }
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
                var editedFilter = savedFilter ?? SavedItemFilter(
                    libraryID: viewModel.parent?.pagingLibraryID,
                    parentID: viewModel.parent?.id,
                    parentType: viewModel.parent?.libraryType,
                    name: trimmedName,
                    filters: viewModel.staticFilters
                        .union(viewModel.currentFilters)
                        .mutating(\.query, with: nil)
                )

                editedFilter.name = trimmedName
                editedFilter.grouping = grouping
                editedFilter.posterDisplayType = posterDisplayType

                if let index = viewModel.savedFilters.firstIndex(where: { $0.id == editedFilter.id }) {
                    viewModel.savedFilters[index] = editedFilter
                } else {
                    viewModel.savedFilters.append(editedFilter)
                }

                if !isPinned {
                    pinnedFilters.removeAll { $0 == editedFilter.id }
                } else if !pinnedFilters.contains(editedFilter.id) {
                    pinnedFilters.append(editedFilter.id)
                }

                Notifications[.savedFiltersDidChange].post()
                router.dismiss()
            }
            .disabled(
                trimmedName.isEmpty ||
                    isDuplicate ||
                    (
                        savedFilter?.name == trimmedName &&
                            savedFilter?.grouping == grouping &&
                            savedFilter?.posterDisplayType == posterDisplayType &&
                            savedFilter.map { pinnedFilters.contains($0.id) } == isPinned
                    )
            )
        }
    }
}
