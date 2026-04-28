//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct IdentifyItemView: View {

    @FocusState
    private var isTitleFocused: Bool

    @Router
    private var router

    @State
    private var query: IdentifyItemViewModel.SearchQuery = .init()

    @StateObject
    private var viewModel: IdentifyItemViewModel

    init(item: BaseItemDto) {
        self._viewModel = StateObject(wrappedValue: IdentifyItemViewModel(item: item))
    }

    var body: some View {
        List {
            ListTitleSection(
                viewModel.item.name ?? L10n.unknown,
                description: viewModel.item.path
            )

            Section(L10n.search) {
                TextField(
                    L10n.title,
                    text: $query.name.map(
                        getter: { $0 ?? "" },
                        setter: { $0.isEmpty ? nil : $0 }
                    )
                )
                .focused($isTitleFocused)

                TextField(
                    L10n.originalTitle,
                    text: $query.originalTitle.map(
                        getter: { $0 ?? "" },
                        setter: { $0.isEmpty ? nil : $0 }
                    )
                )

                TextField(
                    L10n.year,
                    text: $query.year.map(
                        getter: { $0.map(String.init) ?? "" },
                        setter: { $0.isEmpty ? nil : Int($0) }
                    )
                )
                .keyboardType(.numberPad)
            }

            if query.isNotEmpty {
                Section(L10n.items) {
                    if viewModel.searchResults.isNotEmpty {
                        ForEach(viewModel.searchResults) { result in
                            ResultRow(result: result) {
                                router.route(
                                    to: .identifyItemResults(
                                        viewModel: viewModel,
                                        result: result
                                    )
                                )
                            }
                        }
                    } else {
                        Text(L10n.none)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.identify)
        .animation(.linear, value: viewModel.searchResults)
        .navigationBarBackButtonHidden(viewModel.background.is(.updating))
        .onFirstAppear {
            isTitleFocused = true
        }
        .topBarTrailing {
            if viewModel.background.is(.searching) {
                ProgressView()
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                router.dismiss()
            }
        }
        .backport
        .onChange(of: query) { _, newValue in
            viewModel.search(query: newValue)
        }
        .errorMessage($viewModel.error)
    }
}
