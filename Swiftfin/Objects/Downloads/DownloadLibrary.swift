//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import FactoryKit
import JellyfinAPI
import SwiftUI

@MainActor
struct DownloadLibrary: PagingLibrary, SearchablePagingLibrary {

    struct Environment: WithDefaultValue {
        var grouping: BaseItemDto.Grouping?

        static let `default`: Self = .init(grouping: .series)
    }

    let environment: Environment? = .default
    let hasNextPage: Bool = false
    let parent: TitledLibraryParent = .init(
        displayTitle: L10n.downloads,
        id: "downloads"
    )

    func libraryStyleOptions(environment: Environment) -> LibraryStyleOptions {
        BaseItemKind.libraryStyleOptions(for: [.movie, .series, .season, .episode, .boxSet])
    }

    func makeMenuContent(environment: Binding<Environment>) -> AnyView {
        Picker(
            selection: environment.map(
                getter: { $0.grouping },
                setter: { .init(grouping: $0) }
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
            viewModel: viewModel
        )
        .eraseToAnyView()
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [DownloadTask] {
        guard pageState.pageOffset == 0 else { return [] }
        return entries(for: environment)
    }

    func retrieveSearchPage(
        query: String,
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [DownloadTask] {
        guard pageState.pageOffset == 0 else { return [] }
        return entries(for: environment)
            .filter { $0.displayTitle.localizedCaseInsensitiveContains(query) }
    }

    private func entries(for environment: Environment) -> [DownloadTask] {
        let manager = Container.shared.downloadManager()

        let source: [DownloadTask] = if environment.grouping == .episodes {
            manager.tasks.filter { !$0.isContainer }
        } else {
            manager.topLevel()
        }

        let active = source
            .filter { !manager.isFullyCompleted($0) }
            .sorted { lhs, rhs in
                if lhs.state != rhs.state { return lhs.state < rhs.state }
                return lhs.createdAt < rhs.createdAt
            }

        let completed = source
            .filter { manager.isFullyCompleted($0) }
            .sorted { lhs, rhs in
                (lhs.item.sortName ?? lhs.displayTitle) < (rhs.item.sortName ?? rhs.displayTitle)
            }

        return active + completed
    }
}

private struct DownloadLibraryBody<Content: View>: View {

    @ObservedObject
    private var viewModel: PagingLibraryViewModel<DownloadLibrary>

    private let content: Content
    private let downloadManager = Container.shared.downloadManager()

    init(
        content: Content,
        viewModel: PagingLibraryViewModel<DownloadLibrary>
    ) {
        self.content = content
        self.viewModel = viewModel
    }

    var body: some View {
        content
            .onReceive(
                downloadManager.$tasks
                    .dropFirst()
                    .removeDuplicates { lhs, rhs in
                        lhs.map(\.id) == rhs.map(\.id) && lhs.map(\.state) == rhs.map(\.state)
                    }
            ) { _ in
                viewModel.refresh()
            }
    }
}
