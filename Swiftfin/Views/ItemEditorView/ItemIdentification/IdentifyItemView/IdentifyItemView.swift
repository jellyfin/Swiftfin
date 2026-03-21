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

    @Router
    private var router

    @FocusState
    private var isTitleFocused: Bool

    @StateObject
    private var viewModel: IdentifyItemViewModel

    @State
    private var name: String = ""
    @State
    private var originalTitle: String = ""
    @State
    private var year: String = ""

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
                TextField(L10n.title, text: $name)
                    .focused($isTitleFocused)

                TextField(L10n.originalTitle, text: $originalTitle)

                TextField(L10n.year, text: $year)
                    .keyboardType(.numberPad)
            }

            if name.isNotEmpty || originalTitle.isNotEmpty || year.isNotEmpty {
                Section(L10n.items) {
                    if viewModel.searchResults.isNotEmpty {
                        ForEach(viewModel.searchResults) { result in
                            ResultRow(result) {
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
        .animation(.easeInOut, value: viewModel.searchResults)
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
        .onChange(of: name) { newValue in
            viewModel.search(
                name: newValue,
                originalTitle: viewModel.searchParameters.value.originalTitle,
                year: viewModel.searchParameters.value.year
            )
        }
        .onChange(of: originalTitle) { newValue in
            viewModel.search(
                name: viewModel.searchParameters.value.name,
                originalTitle: newValue,
                year: viewModel.searchParameters.value.year
            )
        }
        .onChange(of: year) { newValue in
            viewModel.search(
                name: viewModel.searchParameters.value.name,
                originalTitle: viewModel.searchParameters.value.originalTitle,
                year: Int(newValue)
            )
        }
        .errorMessage($viewModel.error)
    }
}
