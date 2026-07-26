//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import JellyfinAPI
import SwiftUI

struct LayoutGenrePickerView: View {

    @Binding
    var selection: [ItemGenre]
    let library: LibraryReference?
    let itemTypes: [BaseItemKind]

    @Injected(\.currentUserSession)
    private var userSession
    @Router
    private var router

    @State
    private var genres: [ItemGenre] = []
    @State
    private var search = ""
    @State
    private var isLoading = true
    @State
    private var error: ErrorMessage?

    private var choices: [ItemGenre] {
        (genres + selection)
            .uniqued { $0.value }
            .filter { search.isEmpty || $0.displayTitle.localizedCaseInsensitiveContains(search) }
            .sorted { $0.displayTitle.localizedStandardCompare($1.displayTitle) == .orderedAscending }
    }

    @ContentBuilder
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let error {
                ErrorView(error: error)
            } else if choices.isEmpty {
                ContentUnavailableView(
                    search.isEmpty ? L10n.noItems.localizedCapitalized : L10n.noResults.localizedCapitalized,
                    systemImage: "magnifyingglass"
                )
            } else {
                SelectorView(selection: $selection, sources: choices, type: .multi)
            }
        }
        .navigationTitle(L10n.genres)
        .navigationBarCloseButton { router.dismiss() }
        .searchable(text: $search)
        .topBarTrailing {
            Button(L10n.reset) { selection = [] }
                .disabled(selection.isEmpty)
        }
        .refreshable { await loadGenres() }
        .task { await loadGenres() }
    }

    @MainActor
    private func loadGenres() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        guard let userSession else {
            error = ErrorMessage(L10n.signIn)
            return
        }

        do {
            var parameters = Paths.GetQueryFiltersParameters()
            parameters.userID = userSession.user.id
            parameters.parentID = library?.id
            parameters.includeItemTypes = itemTypes.isEmpty ? library?.baseItem.supportedItemTypes ?? LayoutItemTypes.all : itemTypes
            parameters.isRecursive = true
            let response = try await userSession.client.send(Paths.getQueryFilters(parameters: parameters))
            try Task.checkCancellation()
            genres = (response.value.genres ?? []).compactMap(\.name).map(ItemGenre.init(stringLiteral:))
        } catch is CancellationError {
            return
        } catch {
            self.error = ErrorMessage(error.localizedDescription)
        }
    }
}
