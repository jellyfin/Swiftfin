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
import SwiftUI

struct LayoutItemPickerView: View {

    @Injected(\.currentUserSession)
    private var userSession

    @Router
    private var router

    @State
    private var items: [BaseItemDto] = []
    @State
    private var error: ErrorMessage?
    @State
    private var isLoading = true
    @State
    private var searchQuery = ""
    @State
    private var activeRequestID: UUID?
    @State
    private var hasMoreItems = false
    @State
    private var isLoadingMore = false
    @State
    private var loadedQuery = ""
    @State
    private var nextPageStartIndex = 0
    @State
    private var pageError: ErrorMessage?

    private let selectionID: String?
    private let includedItemTypes: [BaseItemKind]
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
        self.includedItemTypes = includedItemTypes
        self.nilSelectionTitle = nilSelectionTitle
        self.title = title
        self.disabledItemIDs = disabledItemIDs
        self.dismissOnSelect = dismissOnSelect
        self.onSelect = onSelect
    }

    private func select(_ item: BaseItemDto?) {
        onSelect(item)
        if dismissOnSelect {
            router.dismiss()
        }
    }

    @ContentBuilder
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                ErrorView(error: error)
            } else {
                itemList
            }
        }
        .navigationTitle(title)
        .searchable(text: $searchQuery)
        .refreshable {
            await getItems(query: normalizedSearchQuery)
        }
        .task(id: searchQuery) {
            do {
                try await Task.sleep(for: .milliseconds(350))
                try Task.checkCancellation()
                await getItems(query: normalizedSearchQuery)
            } catch {}
        }
    }

    private var normalizedSearchQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
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

            if items.isEmpty {
                ContentUnavailableView(
                    normalizedSearchQuery.isEmpty ? L10n.noItems.localizedCapitalized : L10n.noResults.localizedCapitalized,
                    systemImage: normalizedSearchQuery.isEmpty ? "rectangle.on.rectangle.slash" : "magnifyingglass"
                )
                .listRowBackground(Color.clear)
            }

            ForEach(items, id: \.id) { item in
                itemButton(item)
                    .task {
                        if item.id == items.last?.id {
                            await getNextPage()
                        }
                    }
            }

            if let pageError {
                VStack {
                    Text(pageError.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(L10n.retry) {
                        Task { await getNextPage() }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if isLoadingMore {
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

    @MainActor
    private func getItems(query: String) async {
        let requestID = UUID()
        activeRequestID = requestID
        hasMoreItems = false
        isLoading = true
        isLoadingMore = false
        loadedQuery = query
        nextPageStartIndex = 0
        error = nil
        pageError = nil

        defer {
            if activeRequestID == requestID {
                isLoading = false
            }
        }

        guard let userSession else {
            items = []
            error = ErrorMessage(L10n.signIn)
            return
        }

        let parameters = itemParameters(
            query: query,
            startIndex: 0,
            userID: userSession.user.id
        )

        do {
            let response = try await userSession.client.send(
                Paths.getItems(parameters: parameters)
            )
            try Task.checkCancellation()
            guard activeRequestID == requestID else { return }

            let responseItems = response.value.items ?? []
            items = responseItems
                .filter { $0.id?.isEmpty == false }
                .uniqued { $0.id }
            nextPageStartIndex = responseItems.count
            hasMoreItems = responseItems.count == Self.pageSize
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, activeRequestID == requestID else { return }

            items = []
            self.error = ErrorMessage(error.localizedDescription)
        }
    }

    @MainActor
    private func getNextPage() async {
        guard hasMoreItems,
              !isLoading,
              !isLoadingMore,
              let userSession,
              normalizedSearchQuery == loadedQuery,
              let requestID = activeRequestID
        else {
            return
        }

        isLoadingMore = true
        pageError = nil

        defer {
            if activeRequestID == requestID {
                isLoadingMore = false
            }
        }

        let parameters = itemParameters(
            query: loadedQuery,
            startIndex: nextPageStartIndex,
            userID: userSession.user.id
        )

        do {
            let response = try await userSession.client.send(
                Paths.getItems(parameters: parameters)
            )
            try Task.checkCancellation()

            guard activeRequestID == requestID,
                  normalizedSearchQuery == loadedQuery
            else {
                return
            }

            let responseItems = response.value.items ?? []
            items = (items + responseItems)
                .filter { $0.id?.isEmpty == false }
                .uniqued { $0.id }
            nextPageStartIndex += responseItems.count
            hasMoreItems = responseItems.count == Self.pageSize
        } catch {
            guard !Task.isCancelled, activeRequestID == requestID else { return }

            pageError = ErrorMessage(error.localizedDescription)
        }
    }

    private func itemParameters(
        query: String,
        startIndex: Int,
        userID: String
    ) -> Paths.GetItemsParameters {
        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.includeItemTypes = includedItemTypes
        parameters.isRecursive = true
        parameters.limit = Self.pageSize
        parameters.searchTerm = query.isEmpty ? nil : query
        parameters.sortBy = [.name]
        parameters.sortOrder = [.ascending]
        parameters.startIndex = startIndex
        parameters.userID = userID
        return parameters
    }

    private static let pageSize = 100
}
