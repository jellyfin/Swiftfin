//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

@MainActor
struct LiveTVChannelLibrary: PagingLibrary, SearchablePagingLibrary {

    struct Environment: WithDefaultValue {
        var filters: ItemFilterCollection

        static let `default`: Self = .init(filters: .default)
    }

    let environment: Environment?
    let filterViewModel: FilterViewModel
    let parent: BaseItemDto

    init(filters: ItemFilterCollection? = nil) {
        let parent = BaseItemDto(
            collectionType: .livetv,
            id: "liveTV",
            name: L10n.liveTV
        )

        var environment = Environment(filters: filters ?? .default)

        if let id = parent.id, Defaults[.Customization.Library.rememberSort] {
            let storedFilters = StoredValues[.User.libraryFilters(parentID: id)]

            environment.filters.sortBy = storedFilters.sortBy
            environment.filters.sortOrder = storedFilters.sortOrder
        }

        self.environment = environment
        self.filterViewModel = .init(
            parent: parent,
            currentFilters: environment.filters
        )
        self.parent = parent
    }

    func makeLibraryBody(
        viewModel: PagingLibraryViewModel<Self>,
        @ViewBuilder content: @escaping () -> some View
    ) -> AnyView {
        LiveTVChannelLibraryBody(
            filterViewModel: filterViewModel,
            viewModel: viewModel,
            content: content
        )
        .eraseToAnyView()
    }

    func libraryStyleOptions(environment: Environment) -> LibraryStyleOptions {
        BaseItemKind.libraryStyleOptions(for: [.liveTvChannel])
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        let filters = environment.filters

        var parameters = Paths.GetLiveTvChannelsParameters()
        parameters.userID = pageState.userSession.user.id
        parameters.startIndex = pageState.pageOffset
        parameters.limit = pageState.pageSize
        parameters.fields = .MinimumFields
        parameters.enableUserData = true
        parameters.isAddCurrentProgram = true
        parameters.sortBy = filters.sortBy
        parameters.sortOrder = filters.sortOrder.first

        parameters.isMovie = filters.categories.contains(.movies) ? true : nil
        parameters.isSeries = filters.categories.contains(.series) ? true : nil
        parameters.isNews = filters.categories.contains(.news) ? true : nil
        parameters.isKids = filters.categories.contains(.kids) ? true : nil
        parameters.isSports = filters.categories.contains(.sports) ? true : nil
        parameters.isFavorite = filters.traits.contains(.isFavorite) ? true : nil

        let request = Paths.getLiveTvChannels(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }

    func retrieveSearchPage(
        query: String,
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.liveTvChannel]
        parameters.isRecursive = true
        parameters.limit = pageState.pageSize
        parameters.searchTerm = query
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}

private struct LiveTVChannelLibraryBody<Content: View>: View {

    @Default(.Customization.Library.enabledDrawerFilters)
    private var enabledDrawerFilters

    @Router
    private var router

    @ObservedObject
    private var viewModel: PagingLibraryViewModel<LiveTVChannelLibrary>

    private let content: Content
    private let filterViewModel: FilterViewModel

    init(
        filterViewModel: FilterViewModel,
        viewModel: PagingLibraryViewModel<LiveTVChannelLibrary>,
        @ViewBuilder content: () -> Content
    ) {
        self.filterViewModel = filterViewModel
        self.viewModel = viewModel
        self.content = content()
    }

    var body: some View {
        content
            .backport
            .onChange(of: filterViewModel.currentFilters) { _, newFilters in
                rememberSort(from: newFilters)
            }
            .onReceive(
                filterViewModel.$currentFilters
                    .dropFirst()
                    .removeDuplicates()
                    .debounce(for: 1, scheduler: RunLoop.main)
            ) { filters in
                viewModel.environment.filters = filters
            }
        #if os(tvOS)
            .ignoresSafeArea(.all, edges: .horizontal)
            .background(alignment: .top) {
                if !router.isRootOfPath {
                    FocusedPosterCinematicBackgroundView()
                }
            }
        #else
            .navigationBarFilterDrawer(
                viewModel: filterViewModel,
                types: enabledDrawerFilters
            )
        #endif
    }

    private func rememberSort(from filters: ItemFilterCollection) {
        guard let id = viewModel.library.parent.id,
              Defaults[.Customization.Library.rememberSort]
        else { return }

        let storedFilters = StoredValues[.User.libraryFilters(parentID: id)]
            .mutating(\.sortBy, with: filters.sortBy)
            .mutating(\.sortOrder, with: filters.sortOrder)

        StoredValues[.User.libraryFilters(parentID: id)] = storedFilters
    }
}
