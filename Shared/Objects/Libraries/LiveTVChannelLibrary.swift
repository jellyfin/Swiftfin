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
        var grouping: BaseItemDto.Grouping?
        var filters: ItemFilterCollection

        static let `default`: Self = .init(
            grouping: .channels,
            filters: .default
        )
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

        var environment = Environment(
            grouping: parent.groupings?.defaultSelection,
            filters: filters ?? .default
        )

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

    func makeMenuContent(environment: Binding<Environment>) -> AnyView {
        Group {
            if let groupings = parent.groupings, groupings.elements.isNotEmpty {
                Picker(
                    selection: environment.map(
                        getter: { $0.grouping },
                        setter: { grouping in
                            var filters = environment.wrappedValue.filters

                            if grouping != .programs, filters.letter.isNotEmpty {
                                filters.letter = []
                                filterViewModel.currentFilters.letter = []
                            }

                            return .init(grouping: grouping, filters: filters)
                        }
                    )
                ) {
                    ForEach(groupings.elements) { grouping in
                        Text(grouping.displayTitle)
                            .tag(grouping as BaseItemDto.Grouping?)
                    }
                } label: {
                    Text(L10n.grouping)

                    if let grouping = environment.wrappedValue.grouping {
                        Text(grouping.displayTitle)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .eraseToAnyView()
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
        BaseItemKind.libraryStyleOptions(for: parent.supportedItemTypes(for: environment.grouping))
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        switch environment.grouping {
        case .programs:
            try await retrieveProgramsPage(filters: environment.filters, pageState: pageState)
        default:
            try await retrieveChannelsPage(filters: environment.filters, pageState: pageState)
        }
    }

    func retrieveSearchPage(
        query: String,
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        let filters = environment.filters

        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.isRecursive = true
        parameters.limit = pageState.pageSize
        parameters.searchTerm = query
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id
        parameters.sortBy = filters.sortBy
        parameters.sortOrder = filters.sortOrder
        parameters.genres = filters.genres.map(\.value)

        parameters.isMovie = filters.categories.contains(.movies) ? true : nil
        parameters.isSeries = filters.categories.contains(.series) ? true : nil
        parameters.isNews = filters.categories.contains(.news) ? true : nil
        parameters.isKids = filters.categories.contains(.kids) ? true : nil
        parameters.isSports = filters.categories.contains(.sports) ? true : nil
        parameters.isFavorite = filters.traits.contains(.isFavorite) ? true : nil

        switch environment.grouping {
        case .programs:
            parameters.fields = .MinimumFields.appending(.channelInfo)
            parameters.includeItemTypes = [.liveTvProgram]
        default:
            parameters.includeItemTypes = [.liveTvChannel]
        }

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }

    private func retrieveChannelsPage(
        filters: ItemFilterCollection,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
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

    private func retrieveProgramsPage(
        filters: ItemFilterCollection,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        guard filters.letter.isEmpty else {
            return try await retrieveLetteredProgramsPage(filters: filters, pageState: pageState)
        }

        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.userID = pageState.userSession.user.id
        parameters.startIndex = pageState.pageOffset
        parameters.limit = pageState.pageSize
        parameters.fields = .MinimumFields.appending(.channelInfo)
        parameters.enableUserData = true
        parameters.isAiring = true
        parameters.sortBy = filters.sortBy
        parameters.sortOrder = filters.sortOrder
        parameters.genres = filters.genres.map(\.value)

        parameters.isMovie = filters.categories.contains(.movies) ? true : nil
        parameters.isSeries = filters.categories.contains(.series) ? true : nil
        parameters.isNews = filters.categories.contains(.news) ? true : nil
        parameters.isKids = filters.categories.contains(.kids) ? true : nil
        parameters.isSports = filters.categories.contains(.sports) ? true : nil

        let request = Paths.getLiveTvPrograms(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }

    private func retrieveLetteredProgramsPage(
        filters: ItemFilterCollection,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.userID = pageState.userSession.user.id
        parameters.startIndex = pageState.pageOffset
        parameters.limit = pageState.pageSize
        parameters.fields = .MinimumFields.appending(.channelInfo)
        parameters.enableUserData = true
        parameters.isRecursive = true
        parameters.includeItemTypes = [.liveTvProgram]
        parameters.sortBy = filters.sortBy
        parameters.sortOrder = filters.sortOrder
        parameters.genres = filters.genres.map(\.value)

        parameters.isMovie = filters.categories.contains(.movies) ? true : nil
        parameters.isSeries = filters.categories.contains(.series) ? true : nil
        parameters.isNews = filters.categories.contains(.news) ? true : nil
        parameters.isKids = filters.categories.contains(.kids) ? true : nil
        parameters.isSports = filters.categories.contains(.sports) ? true : nil

        if filters.letter.first?.value == "#" {
            parameters.nameLessThan = "A"
        } else {
            parameters.nameStartsWith = filters.letter
                .map(\.value)
                .filter { $0 != "#" }
                .first
        }

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
            .letterPickerBar(
                filterViewModel: viewModel.environment.grouping == .programs ? filterViewModel : nil
            )
            .onFirstAppear {
                Task {
                    await filterViewModel.getQueryFilters()
                }
            }
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
