//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import FactoryKit
import JellyfinAPI
import SwiftUI

@MainActor
struct DownloadLibrary: PagingLibrary, SearchablePagingLibrary, WithRandomElementLibrary {

    struct Environment: WithDefaultValue {
        var filters: ItemFilterCollection

        static let `default`: Self = .init(filters: .default)
    }

    let environment: Environment?
    let hasNextPage: Bool = false
    let filterViewModel: FilterViewModel
    let parent: TitledLibraryParent

    init(
        displayTitle: String = L10n.downloads,
        filters: ItemFilterCollection? = nil
    ) {
        let filters = filters ?? .default
        let parent = TitledLibraryParent(
            displayTitle: displayTitle,
            id: "downloads"
        )

        self.environment = .init(filters: filters)
        self.parent = parent
        self.filterViewModel = .init(
            parent: parent,
            currentFilters: filters,
            localQueryFilters: { Self.localQueryFilters() }
        )
    }

    private static func localQueryFilters() -> QueryFiltersLegacy {
        let completed = Container.shared.downloadManager().tasks.filter(\.isCompleted)

        let genres = Set(completed.compactMap(\.item.genres).flatMap(\.self))
        let tags = Set(completed.compactMap(\.item.tags).flatMap(\.self))
        let years = Set(completed.compactMap(\.item.productionYear))

        return QueryFiltersLegacy(
            genres: genres.sorted(),
            tags: tags.sorted(),
            years: years.sorted()
        )
    }

    func libraryStyleOptions(environment: Environment) -> LibraryStyleOptions {
        BaseItemKind.libraryStyleOptions(for: [.movie, .series, .season, .episode, .boxSet])
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
    ) async throws -> [BaseItemDto] {
        guard pageState.pageOffset == 0 else { return [] }
        return entries(for: environment)
    }

    func retrieveSearchPage(
        query: String,
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        guard pageState.pageOffset == 0 else { return [] }
        return entries(for: environment)
            .filter { $0.displayTitle.localizedCaseInsensitiveContains(query) }
    }

    func retrieveRandomElement(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> BaseItemDto? {
        entries(for: environment).randomElement()
    }

    private func entries(for environment: Environment) -> [BaseItemDto] {
        let manager = Container.shared.downloadManager()
        let source = manager.topLevel()

        let active = source
            .filter { !manager.isFullyCompleted($0) }
            .sorted { lhs, rhs in
                if lhs.state != rhs.state { return lhs.state < rhs.state }
                return lhs.createdAt < rhs.createdAt
            }
            .map(\.item)

        let completed = source
            .filter { manager.isFullyCompleted($0) }
            .map(\.item)
            .filtered(using: environment.filters)

        return active + completed
    }
}

private struct DownloadLibraryBody<Content: View>: View {

    @Default(.Customization.Library.enabledDrawerFilters)
    private var enabledDrawerFilters

    @Injected(\.downloadManager)
    private var downloadManager

    @ObservedObject
    private var viewModel: PagingLibraryViewModel<DownloadLibrary>

    private let content: Content
    private let filterViewModel: FilterViewModel

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
                    await filterViewModel.getQueryFilters()
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
                    .removeDuplicates { lhs, rhs in
                        lhs.map(\.id) == rhs.map(\.id) && lhs.map(\.state) == rhs.map(\.state)
                    }
            ) { _ in
                viewModel.refreshForEnvironmentChange()

                Task {
                    await filterViewModel.getQueryFilters()
                }
            }
        #if !os(tvOS)
            .navigationBarFilterDrawer(
                viewModel: filterViewModel,
                types: enabledDrawerFilters
            )
        #endif
    }
}
