//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import SwiftUI

@MainActor
struct ChannelLibrary: PagingLibrary {

    struct Environment: WithDefaultValue {
        var filters: ItemFilterCollection

        static let `default`: Self = .init(
            filters: .init(
                sortBy: [ItemSortBy.sortName],
                sortOrder: [ItemSortOrder.ascending]
            )
        )
    }

    let environment: Environment?
    let filterViewModel: FilterViewModel
    let parent: TitledLibraryParent = .init(displayTitle: L10n.channels, id: "channels")

    init() {
        self.environment = .default
        self.filterViewModel = .init(
            allFilters: .init(
                categories: ChannelCategory.allCases,
                sortBy: [.name, .sortName],
                sortOrder: ItemSortOrder.allCases,
                traits: [ItemTrait.isFavorite]
            )
        )
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [ChannelProgram] {
        var parameters = Paths.GetLiveTvChannelsParameters()
        parameters.fields = .MinimumFields
        parameters.limit = pageState.pageSize
        parameters.sortBy = environment.filters.sortBy
        parameters.sortOrder = environment.filters.sortOrder.first
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        if environment.filters.traits.contains(ItemTrait.isFavorite) {
            parameters.isFavorite = true
        }

        let categories = environment.filters.categories

        parameters.isMovie = categories.contains(.movies) ? true : nil
        parameters.isSeries = categories.contains(.series) ? true : nil
        parameters.isNews = categories.contains(.news) ? true : nil
        parameters.isKids = categories.contains(.kids) ? true : nil
        parameters.isSports = categories.contains(.sports) ? true : nil

        let request = Paths.getLiveTvChannels(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try await getPrograms(
            for: response.value.items ?? [],
            pageState: pageState
        )
    }

    func makeLibraryBody(
        viewModel: PagingLibraryViewModel<Self>,
        @ViewBuilder content: @escaping () -> some View
    ) -> AnyView {
        ChannelLibraryBody(
            filterViewModel: filterViewModel,
            viewModel: viewModel,
            content: content
        )
        .eraseToAnyView()
    }

    private func getPrograms(
        for channels: [BaseItemDto],
        pageState: LibraryPageState
    ) async throws -> [ChannelProgram] {
        guard let minEndDate = Calendar.current.date(byAdding: .hour, value: -1, to: .now),
              let maxStartDate = Calendar.current.date(byAdding: .hour, value: 6, to: .now)
        else { return [] }

        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.channelIDs = channels.compactMap(\.id)
        parameters.maxStartDate = maxStartDate
        parameters.minEndDate = minEndDate
        parameters.sortBy = [.startDate]
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getLiveTvPrograms(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        let groupedPrograms = (response.value.items ?? [])
            .grouped { program in
                channels.first(where: { $0.id == program.channelID })
            }

        return channels.map { channel in
            ChannelProgram(
                channel: channel,
                programs: groupedPrograms[channel] ?? []
            )
        }
    }
}

private struct ChannelLibraryBody<Content: View>: View {

    @ObservedObject
    private var viewModel: PagingLibraryViewModel<ChannelLibrary>

    private let content: Content
    private let filterViewModel: FilterViewModel

    init(
        filterViewModel: FilterViewModel,
        viewModel: PagingLibraryViewModel<ChannelLibrary>,
        @ViewBuilder content: () -> Content
    ) {
        self.filterViewModel = filterViewModel
        self.viewModel = viewModel
        self.content = content()
    }

    var body: some View {
        content
            .onReceive(
                filterViewModel.$currentFilters
                    .dropFirst()
                    .removeDuplicates()
                    .debounce(for: 1, scheduler: RunLoop.main)
            ) { filters in
                viewModel.environment.filters = filters
            }
        #if os(iOS)
            .navigationBarFilterDrawer(
                viewModel: filterViewModel,
                types: [.sortBy, .traits, .category]
            )
        #endif
    }
}
