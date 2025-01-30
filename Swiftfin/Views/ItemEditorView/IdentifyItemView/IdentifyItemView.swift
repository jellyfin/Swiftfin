//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct IdentifyItemView: View {

    private struct SearchFields: Equatable {
        var name: String?
        var originalTitle: String?
        var year: Int?

        var isEmpty: Bool {
            name.isNilOrEmpty &&
                originalTitle.isNilOrEmpty &&
                year == nil
        }
    }

    @Default(.accentColor)
    private var accentColor

    @FocusState
    private var isTitleFocused: Bool

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: ItemEditorCoordinator.Router

    @StateObject
    private var viewModel: IdentifyItemViewModel

    // MARK: - Identity Variables

    @State
    private var selectedResult: RemoteSearchResult?

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Lookup States

    @State
    private var search = SearchFields()

    // MARK: - Initializer

    init(item: BaseItemDto) {
        self._viewModel = StateObject(wrappedValue: IdentifyItemViewModel(item: item))
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.state {
            case .content, .searching:
                contentView
            case .updating:
                ProgressView()
            }
        }
        .navigationTitle(L10n.identify)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.state == .updating)
        .sheet(item: $selectedResult) {
            selectedResult = nil
        } content: { result in
            RemoteSearchResultView(
                result: result,
                onSave: {
                    selectedResult = nil
                    viewModel.send(.update(result))
                },
                onClose: {
                    selectedResult = nil
                }
            )
        }
        .onReceive(viewModel.events) { events in
            switch events {
            case let .error(eventError):
                error = eventError
            case .cancelled:
                selectedResult = nil
            case .updated:
                router.pop()
            }
        }
        .errorMessage($error)
        .onFirstAppear {
            isTitleFocused = true
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        Form {
            searchView

            resultsView
        }
    }

    // MARK: - Search View

    @ViewBuilder
    private var searchView: some View {
        Section(L10n.search) {
            TextField(
                L10n.title,
                text: $search.name.coalesce("")
            )
            .focused($isTitleFocused)

            TextField(
                L10n.originalTitle,
                text: $search.originalTitle.coalesce("")
            )

            TextField(
                L10n.year,
                text: $search.year
                    .map(
                        getter: { $0 == nil ? "" : "\($0!)" },
                        setter: { Int($0) }
                    )
            )
            .keyboardType(.numberPad)
        }

        if viewModel.state == .searching {
            ListRowButton(L10n.cancel) {
                viewModel.send(.cancel)
            }
            .foregroundStyle(.red, .red.opacity(0.2))
        } else {
            ListRowButton(L10n.search) {
                viewModel.send(.search(
                    name: search.name,
                    originalTitle: search.originalTitle,
                    year: search.year
                ))
            }
            .disabled(search.isEmpty)
            .foregroundStyle(
                accentColor.overlayColor,
                accentColor
            )
        }
    }

    // MARK: - Results View

    @ViewBuilder
    private var resultsView: some View {
        if viewModel.searchResults.isNotEmpty {
            Section(L10n.items) {
                ForEach(viewModel.searchResults) { result in
                    RemoteSearchResultRow(result: result) {
                        selectedResult = result
                    }
                }
            }
        }
    }

    // MARK: - Result Image

    @ViewBuilder
    static func resultImage(_ url: URL?) -> some View {
        ZStack {
            Color.clear

            ImageView(url)
                .failure {
                    Image(systemName: "questionmark")
                        .foregroundStyle(.primary)
                }
        }
        .posterStyle(.portrait)
        .posterShadow()
    }
}
