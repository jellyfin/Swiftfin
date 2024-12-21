//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct ItemIdentifyView: View {

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: ItemEditorCoordinator.Router

    @ObservedObject
    private var viewModel: ItemIdentifyViewModel

    // MARK: - Identity Variables

    @State
    private var selectedMatch: RemoteSearchResult?

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Lookup States

    @State
    var search = ItemIdentifySearch()
    @State
    var lastSearch = ItemIdentifySearch()

    // MARK: - Initializer

    init(item: BaseItemDto) {
        self.viewModel = .init(item: item)
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        Group {
            switch viewModel.state {
            case .updating:
                updateView
            case .initial:
                contentView
            }
        }
        .navigationBarTitle(L10n.identify)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { selectedMatch != nil },
            set: { if !$0 { selectedMatch = nil } }
        )) {
            if let match = selectedMatch {
                ItemInfoConfirmationView(
                    itemInfo: match,
                    remoteImage: resultImage(match.imageURL)
                ) {
                    viewModel.send(.update(match))
                    selectedMatch = nil
                } onClose: {
                    selectedMatch = nil
                }
            }
        }
        .navigationBarBackButtonHidden(viewModel.state == .updating)
        .onReceive(viewModel.events) { events in
            switch events {
            case let .error(eventError):
                error = eventError
            case .cancelled:
                selectedMatch = nil
            case .updated:
                router.pop()
            }
        }
        .errorMessage($error)
    }

    // MARK: - UpdatE View

    @ViewBuilder
    var updateView: some View {
        VStack(alignment: .center, spacing: 16) {
            ProgressView()
            Button(L10n.cancel, role: .destructive) {
                viewModel.send(.cancel)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        Form {
            searchView
            resultsView
        }
        .topBarTrailing {
            Button(L10n.search) {
                viewModel.send(.search(search))
                lastSearch = search
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.state == .updating || search == lastSearch)
        }
    }

    // MARK: - Search View

    @ViewBuilder
    private var searchView: some View {
        Section(header: Text(L10n.search)) {
            TextField(L10n.title, text: Binding(
                get: { search.name ?? "" },
                set: { search.name = $0.isEmpty ? nil : $0 }
            ))

            TextField(L10n.originalTitle, text: Binding(
                get: { search.originalTitle ?? "" },
                set: { search.originalTitle = $0.isEmpty ? nil : $0 }
            ))

            TextField(L10n.year, text: Binding(
                get: { search.year?.description ?? "" },
                set: { search.year = $0.isEmpty ? nil : Int($0) }
            ))
            .keyboardType(.numberPad)
        }
    }

    // MARK: - Results View

    @ViewBuilder
    private var resultsView: some View {
        if viewModel.searchResults.isNotEmpty {
            Section(L10n.items) {
                ForEach(viewModel.searchResults, id: \.id) { remoteSearchResult in
                    RemoteSearchResultButton(
                        remoteSearchResult: remoteSearchResult,
                        remoteImage: resultImage(remoteSearchResult.imageURL)
                    ) {
                        selectedMatch = remoteSearchResult
                    }
                }
            }
        }
    }

    // MARK: - Result Image

    @ViewBuilder
    public func resultImage(_ url: String? = nil) -> some View {
        ZStack {
            Color.clear

            ImageView(URL(string: url ?? ""))
                .failure {
                    SystemImageContentView(systemName: "questionmark")
                }
        }
        .posterStyle(.portrait)
        .posterShadow()
    }
}
