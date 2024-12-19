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
    private var router: ItemEditorCoordinator.Router

    @ObservedObject
    private var viewModel: ItemInfoViewModel<SearchInfo>

    // MARK: - Identity Variables

    @State
    private var lastSearch: SearchInfo?
    @State
    private var tempSearchInfo: SearchInfo?
    @State
    private var selectedMatch: RemoteSearchResult?

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Potential States

    @State
    var boxSetInfo = BoxSetInfo()
    @State
    var movieInfo = MovieInfo()
    @State
    var personInfo = PersonLookupInfo()
    @State
    var seriesInfo = SeriesInfo()

    // MARK: - Initializer

    init(viewModel: ItemInfoViewModel<SearchInfo>) {
        self.viewModel = viewModel
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
        .navigationBarTitle(L10n.metadata)
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
        .topBarTrailing {
            Button(L10n.search) {
                if let tempSearchInfo {
                    lastSearch = tempSearchInfo
                    viewModel.send(.search(tempSearchInfo))
                }
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.state == .updating || tempSearchInfo == nil || lastSearch == tempSearchInfo)
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
        VStack(alignment: .center) {
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
            switch viewModel.item.type {
            case .boxSet:
                boxSetSearchView
            case .movie:
                movieSearchView
            case .person:
                personSearchView
            case .series:
                seriesSearchView
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

    // MARK: - Box Set Search View

    @ViewBuilder
    private var boxSetSearchView: some View {
        Section(header: Text(L10n.search)) {
            TextField(
                L10n.name,
                text: Binding(
                    get: { boxSetInfo.name ?? "" },
                    set: { newValue in
                        boxSetInfo.name = newValue
                        tempSearchInfo = boxSetInfo as? SearchInfo
                    }
                )
            )

            TextField(
                L10n.originalTitle,
                text: Binding(
                    get: { boxSetInfo.originalTitle ?? "" },
                    set: { newValue in
                        boxSetInfo.originalTitle = newValue
                        tempSearchInfo = boxSetInfo as? SearchInfo
                    }
                )
            )

            TextField(
                L10n.year,
                text: Binding(
                    get: { boxSetInfo.year.map(String.init) ?? "" },
                    set: { newValue in
                        boxSetInfo.year = Int(newValue)
                        tempSearchInfo = boxSetInfo as? SearchInfo
                    }
                )
            )
            .keyboardType(.numberPad)
        }
    }

    // MARK: - Movie Search View

    @ViewBuilder
    private var movieSearchView: some View {
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

    // MARK: - Person Search View

    @ViewBuilder
    private var personSearchView: some View {
        Section(header: Text(L10n.search)) {
            TextField(
                L10n.name,
                text: Binding(
                    get: { personInfo.name ?? "" },
                    set: { newValue in
                        personInfo.name = newValue
                        tempSearchInfo = personInfo as? SearchInfo
                    }
                )
            )

            TextField(
                L10n.originalTitle,
                text: Binding(
                    get: { personInfo.originalTitle ?? "" },
                    set: { newValue in
                        personInfo.originalTitle = newValue
                        tempSearchInfo = personInfo as? SearchInfo
                    }
                )
            )

            TextField(
                L10n.year,
                text: Binding(
                    get: { personInfo.year.map(String.init) ?? "" },
                    set: { newValue in
                        personInfo.year = Int(newValue)
                        tempSearchInfo = personInfo as? SearchInfo
                    }
                )
            )
            .keyboardType(.numberPad)
        }
    }

    // MARK: - Series Search View

    @ViewBuilder
    private var seriesSearchView: some View {
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
