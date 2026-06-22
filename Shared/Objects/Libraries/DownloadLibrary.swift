//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import JellyfinAPI
import SwiftUI

@MainActor
struct DownloadLibrary: PagingLibrary, SearchablePagingLibrary {

    struct Environment: WithDefaultValue {
        var grouping: BaseItemDto.Grouping?
        var filters: ItemFilterCollection

        static let `default`: Self = .init(grouping: .series, filters: .default)
    }

    let environment: Environment?
    let filterViewModel: FilterViewModel
    let parent: TitledLibraryParent

    init(filters: ItemFilterCollection? = nil) {
        let parent = TitledLibraryParent(displayTitle: L10n.downloads, id: "downloads")
        let environment = Environment(grouping: .series, filters: filters ?? .default)

        self.environment = environment
        self.filterViewModel = .init(parent: parent, currentFilters: environment.filters)
        self.parent = parent
    }

    func makeMenuContent(environment: Binding<Environment>) -> AnyView {
        Picker(
            selection: environment.map(
                getter: { $0.grouping },
                setter: { .init(grouping: $0, filters: environment.wrappedValue.filters) }
            )
        ) {
            Text(BaseItemDto.Grouping.series.displayTitle)
                .tag(BaseItemDto.Grouping.series as BaseItemDto.Grouping?)
            Text(BaseItemDto.Grouping.episodes.displayTitle)
                .tag(BaseItemDto.Grouping.episodes as BaseItemDto.Grouping?)
        } label: {
            Text(L10n.grouping)

            if let grouping = environment.wrappedValue.grouping {
                Text(grouping.displayTitle)
            }
        }
        .pickerStyle(.menu)
        .eraseToAnyView()
    }

    func makeLibraryBody(
        viewModel: PagingLibraryViewModel<Self>,
        @ViewBuilder content: @escaping () -> some View
    ) -> AnyView {
        DownloadLibraryBody(
            content: content(),
            filterViewModel: filterViewModel,
            viewModel: viewModel
        )
        .eraseToAnyView()
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [DownloadTask] {
        page(of: entries(for: environment), pageState: pageState)
    }

    func retrieveSearchPage(
        query: String,
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [DownloadTask] {
        let matching = entries(for: environment)
            .filter { $0.displayTitle.localizedCaseInsensitiveContains(query) }
        return page(of: matching, pageState: pageState)
    }

    private func page(of entries: [DownloadTask], pageState: LibraryPageState) -> [DownloadTask] {
        guard pageState.pageOffset < entries.count else { return [] }
        let endIndex = min(pageState.pageOffset + pageState.pageSize, entries.count)
        return Array(entries[pageState.pageOffset ..< endIndex])
    }

    private func entries(for environment: Environment) -> [DownloadTask] {
        let manager = Container.shared.downloadManager()

        let source: [DownloadTask] = if environment.grouping == .episodes {
            manager.tasks.filter { !$0.isContainer }
        } else {
            manager.topLevel()
        }

        let completed = source.filter { manager.isFullyCompleted($0) }
        let completedIDs = Set(completed.map(\.id))
        let active = source
            .filter { !completedIDs.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.state != rhs.state { return lhs.state < rhs.state }
                return lhs.createdAt < rhs.createdAt
            }

        return active + filtered(completed, using: environment.filters)
    }

    private func filtered(_ source: [DownloadTask], using filters: ItemFilterCollection) -> [DownloadTask] {
        var items = source

        if filters.genres.isNotEmpty {
            let allowed = Set(filters.genres.map(\.value))
            items = items.filter {
                guard let genres = $0.item.genres else { return false }
                return !allowed.isDisjoint(with: genres)
            }
        }

        if filters.tags.isNotEmpty {
            let allowed = Set(filters.tags.map(\.value))
            items = items.filter {
                guard let tags = $0.item.tags else { return false }
                return !allowed.isDisjoint(with: tags)
            }
        }

        if filters.years.isNotEmpty {
            let allowed = Set(filters.years.compactMap { Int($0.value) })
            items = items.filter {
                guard let year = $0.item.productionYear else { return false }
                return allowed.contains(year)
            }
        }

        if filters.letter.isNotEmpty {
            let allowed = Set(filters.letter.map(\.value))
            items = items.filter {
                let sortName = $0.item.sortName ?? $0.item.displayTitle
                guard let first = sortName.first else { return false }
                if first.isLetter {
                    return allowed.contains(String(first).uppercased())
                }
                return allowed.contains("#")
            }
        }

        if filters.traits.contains(where: { $0.value == ItemTrait.isFavorite.value }) {
            items = items.filter { $0.item.userData?.isFavorite == true }
        }
        if filters.traits.contains(where: { $0.value == ItemTrait.isPlayed.value }) {
            items = items.filter { $0.item.userData?.isPlayed == true }
        }
        if filters.traits.contains(where: { $0.value == ItemTrait.isUnplayed.value }) {
            items = items.filter { $0.item.userData?.isPlayed != true }
        }

        if let primarySort = filters.sortBy.first {
            let ascending = filters.sortOrder.first == .ascending
            items.sort { lhs, rhs in
                let comparison = lhs.compare(to: rhs, by: primarySort)
                return ascending ? comparison : !comparison
            }
        }

        return items
    }
}

private struct DownloadLibraryBody<Content: View>: View {

    @Default(.Customization.Library.enabledDrawerFilters)
    private var enabledDrawerFilters

    @ObservedObject
    private var viewModel: PagingLibraryViewModel<DownloadLibrary>

    private let content: Content
    private let filterViewModel: FilterViewModel
    private let downloadManager = Container.shared.downloadManager()

    init(
        content: Content,
        filterViewModel: FilterViewModel,
        viewModel: PagingLibraryViewModel<DownloadLibrary>
    ) {
        self.content = content
        self.filterViewModel = filterViewModel
        self.viewModel = viewModel
    }

    var body: some View {
        content
            .letterPickerBar(filterViewModel: filterViewModel)
            .onFirstAppear {
                Task {
                    await filterViewModel.getQueryFilters(isDownloads: true)
                }
            }
            .onReceive(
                filterViewModel.$currentFilters
                    .dropFirst()
                    .removeDuplicates()
                    .debounce(for: 1, scheduler: RunLoop.main)
            ) { filters in
                viewModel.environment.filters = filters
            }
            .onReceive(
                downloadManager.$tasks
                    .dropFirst()
                    .removeDuplicates { $0.map(\.id) == $1.map(\.id) }
            ) { _ in
                viewModel.refresh()
            }
        #if os(iOS)
            .navigationBarFilterDrawer(
                viewModel: filterViewModel,
                types: enabledDrawerFilters
            )
        #endif
    }
}
