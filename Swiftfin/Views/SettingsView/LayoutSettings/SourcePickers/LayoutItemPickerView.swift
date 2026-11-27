//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LayoutItemPickerView: View {

    @Router
    private var router

    @State
    private var isSearchPresented = false
    @State
    private var searchError: Error?
    @State
    private var viewModel: PagingLibraryViewModel<ItemLibrary>

    private let selectionID: String?
    private let nilSelectionTitle: String?
    private let title: String
    private let disabledItemIDs: Set<String>
    private let dismissOnSelect: Bool
    private let onSelect: (BaseItemDto?) -> Void

    init(
        selectionID: String?,
        includedItemTypes: [BaseItemKind],
        nilSelectionTitle: String?,
        title: String,
        disabledItemIDs: Set<String> = [],
        dismissOnSelect: Bool = true,
        onSelect: @escaping (BaseItemDto?) -> Void
    ) {
        self.selectionID = selectionID
        self._viewModel = State(initialValue: PagingLibraryViewModel(
            library: ItemLibrary(
                parent: BaseItemDto(),
                filters: .init(itemTypes: includedItemTypes, sortBy: [.name]),
                useRememberedFilters: false
            ),
            pageSize: 100,
            refreshesForStoreChanges: false
        ))
        self.nilSelectionTitle = nilSelectionTitle
        self.title = title
        self.disabledItemIDs = disabledItemIDs
        self.dismissOnSelect = dismissOnSelect
        self.onSelect = onSelect
    }

    private func select(_ item: BaseItemDto?) {
        // End search before its text field is removed from the navigation stack.
        if dismissOnSelect {
            isSearchPresented = false
        }
        onSelect(item)
        if dismissOnSelect {
            router.dismiss()
        }
    }

    @ContentBuilder
    var body: some View {
        Group {
            if viewModel.background.is(.searching) {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = searchError, viewModel.searchElements.isEmpty, viewModel.isSearchActive {
                ErrorView(error: error)
            } else {
                itemList
            }
        }
        .navigationTitle(title)
        .searchable(text: $viewModel.searchQuery, isPresented: $isSearchPresented)
        .onReceive(viewModel.events.compactMap(\.error)) { error in
            searchError = error
        }
        .onChange(of: viewModel.searchQuery) {
            searchError = nil
        }
        .refreshable {
            searchError = nil
            await viewModel.search(query: viewModel.searchQuery.nilIfBlank ?? "")
        }
    }

    @ContentBuilder
    private var itemList: some View {
        List {
            if let nilSelectionTitle {
                Button {
                    select(nil)
                } label: {
                    HStack {
                        Text(nilSelectionTitle)
                            .foregroundStyle(.primary)

                        Spacer()

                        if selectionID == nil {
                            ListRowCheckbox()
                                .isEditing(true)
                                .isSelected(true)
                                .accessibilityHidden(true)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectionID == nil ? .isSelected : [])
            }

            if viewModel.searchElements.isEmpty {
                ContentUnavailableView(
                    viewModel.isSearchActive ? L10n.noResults.localizedCapitalized : L10n.search,
                    systemImage: "magnifyingglass"
                )
                .listRowBackground(Color.clear)
            }

            ForEach(viewModel.searchElements) { item in
                itemButton(item.snapshot)
                    .onAppear {
                        if item.id == viewModel.searchElements.last?.id {
                            viewModel.getNextSearchPage()
                        }
                    }
            }

            if let error = searchError, !viewModel.searchElements.isEmpty {
                VStack {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(L10n.retry) {
                        searchError = nil
                        viewModel.getNextSearchPage()
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if viewModel.background.is(.gettingNextSearchPage) {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
        }
    }

    private func itemButton(_ item: BaseItemDto) -> some View {
        let isSelected = selectionID == item.id

        return Button {
            select(item)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.displayTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let subtitle = subtitle(for: item) {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    ListRowCheckbox()
                        .isEditing(true)
                        .isSelected(true)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(item.id.map(disabledItemIDs.contains) ?? true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func subtitle(for item: BaseItemDto) -> String? {
        var components: [String] = []

        if let type = item.type {
            components.append(type.displayTitle.localizedCapitalized)
        }

        if item.type == .episode, let episode = item.seasonEpisodeLabel {
            components.append(episode)
        }

        if let parentTitle = item.parentTitle,
           parentTitle != item.displayTitle {
            components.append(parentTitle)
        }

        if let productionYear = item.productionYear {
            components.append(productionYear.description)
        }

        return components.isEmpty ? nil : components.joined(separator: " • ")
    }
}
