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

struct IdentifyItemView<SearchInfo: Equatable>: View {

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @ObservedObject
    private var viewModel: ItemInfoViewModel<SearchInfo>

    // MARK: - Identity Variables

    @State
    private var tempSearchInfo: SearchInfo? = nil
    @State
    private var selectedMatch: RemoteSearchResult? = nil

    // MARK: - State Variables for Search Info

    @State
    private var movieInfo = MovieInfo()
    @State
    private var seriesInfo = SeriesInfo()

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: ItemInfoViewModel<SearchInfo>) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        contentView
            .navigationBarTitle(L10n.metadata)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: Binding(
                get: { selectedMatch != nil },
                set: { if !$0 { selectedMatch = nil } }
            )) {
                if let selectedMatch {
                    selectionConfirmationModal(selectedMatch)
                }
            }
            .topBarTrailing {
                Button(L10n.search) {
                    if let tempSearchInfo {
                        viewModel.send(.search(tempSearchInfo))
                    }
                }
                .buttonStyle(.toolbarPill)
            }
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .onReceive(viewModel.events) { events in
                switch events {
                case let .error(eventError):
                    error = eventError
                default:
                    break
                }
            }
            .errorMessage($error)
    }

    @ViewBuilder
    var contentView: some View {
        Form {
            switch viewModel.item.type {
            case .movie:
                movieSearch
            case .series:
                seriesSearch
            default:
                EmptyView()
            }
            searchResultsView
        }
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResultsView: some View {
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

    // MARK: - Movie Search Fields

    @ViewBuilder
    private var movieSearch: some View {
        Section(header: Text(L10n.search)) {
            TextField(
                L10n.name,
                text: Binding(
                    get: { movieInfo.name ?? "" },
                    set: { newValue in
                        movieInfo.name = newValue
                        tempSearchInfo = movieInfo as? SearchInfo
                    }
                )
            )

            TextField(
                L10n.originalTitle,
                text: Binding(
                    get: { movieInfo.originalTitle ?? "" },
                    set: { newValue in
                        movieInfo.originalTitle = newValue
                        tempSearchInfo = movieInfo as? SearchInfo
                    }
                )
            )

            TextField(
                L10n.year,
                text: Binding(
                    get: { movieInfo.year.map(String.init) ?? "" },
                    set: { newValue in
                        movieInfo.year = Int(newValue)
                        tempSearchInfo = movieInfo as? SearchInfo
                    }
                )
            )
            .keyboardType(.numberPad)
        }
    }

    // MARK: - Series Search Fields

    @ViewBuilder
    private var seriesSearch: some View {
        Section(header: Text(L10n.search)) {
            TextField(
                L10n.name,
                text: Binding(
                    get: { seriesInfo.name ?? "" },
                    set: { newValue in
                        seriesInfo.name = newValue
                        tempSearchInfo = seriesInfo as? SearchInfo
                    }
                )
            )

            TextField(
                L10n.originalTitle,
                text: Binding(
                    get: { seriesInfo.originalTitle ?? "" },
                    set: { newValue in
                        seriesInfo.originalTitle = newValue
                        tempSearchInfo = seriesInfo as? SearchInfo
                    }
                )
            )

            TextField(
                L10n.year,
                text: Binding(
                    get: { seriesInfo.year.map(String.init) ?? "" },
                    set: { newValue in
                        seriesInfo.year = Int(newValue)
                        tempSearchInfo = seriesInfo as? SearchInfo
                    }
                )
            )
            .keyboardType(.numberPad)
        }
    }

    // MARK: - Selection Confirmation Modal

    @ViewBuilder
    private func selectionConfirmationModal(_ selected: RemoteSearchResult) -> some View {
        NavigationView {
            VStack(alignment: .leading) {
                resultImage(selected.imageURL)
                    .frame(width: 60, height: 180)
                    .padding(.leading)
                    .padding()
                Text(selected.premiereDate?.formatted(.dateTime.year().month().day()) ?? .emptyDash)
                    .foregroundStyle(Color.primary)
                    .padding()
                Text(selected.overview ?? L10n.unknown)
                    .foregroundStyle(Color.secondary)
                    .padding()
                Text(selected.searchProviderName ?? L10n.unknown)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(selected.name ?? L10n.unknown)
            .navigationBarCloseButton {
                selectedMatch = nil
            }
            .topBarTrailing {
                Button(L10n.save) {
                    viewModel.send(.update(selected))
                    selectedMatch = nil
                    router.dismissCoordinator()
                }
                .buttonStyle(.toolbarPill)
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
