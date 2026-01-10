//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import SwiftUI

struct EpisodeGroup<Library: PagingLibrary>: _ContentGroup where Library.Element == BaseItemDto {

    var displayTitle: String {
        library.parent.displayTitle
    }

    let id: String
    let library: Library
    let viewModel: PagingLibraryViewModel<Library>

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty
    }

    init(
        id: String = UUID().uuidString,
        library: Library
    ) {
        self.id = id
        self.library = library
        self.viewModel = .init(library: library, pageSize: 20)
    }

    @ViewBuilder
    func body(with viewModel: PagingLibraryViewModel<Library>) -> some View {
        WithRouter { router in
            EpisodeHStack(
                viewModel: viewModel,
                playButtonItemID: nil
            ) {
                #if os(tvOS)
                Text(viewModel.library.parent.displayTitle)
                    .font(.title3)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                    .edgePadding(.horizontal)
                #else
                Button {
                    router.route(to: .library(library: viewModel.library))
                } label: {
                    HStack(spacing: 3) {
                        Text(viewModel.library.parent.displayTitle)
                            .font(.title2)
                            .lineLimit(1)

                        Image(systemName: "chevron.forward")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .fontWeight(.semibold)
                }
                .foregroundStyle(.primary, .secondary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityAction(named: Text("Open library")) { router.route(to: .library(library: viewModel.library)) }
                .edgePadding(.horizontal)
                #endif
            }
        }
    }
}

struct EpisodeHStack<Library: PagingLibrary, Header: View>: View where Library.Element == BaseItemDto {

    private enum Element: Identifiable {
        case empty
        case element(BaseItemDto)
        case error(Error)
        case loading

        var id: Int {
            switch self {
            case let .element(episode):
                episode.unwrappedIDHashOrZero
            default:
                UUID().hashValue
            }
        }
    }

    @ViewContextContains(.isInParent)
    private var isInParent

    @ObservedObject
    private var viewModel: PagingLibraryViewModel<Library>

    @Router
    private var router

    @State
    private var didScrollToPlayButtonItem = false

    @StateObject
    private var proxy = CollectionHStackProxy()

    private let header: Header
    private let playButtonItemID: BaseItemDto.ID?

    init(
        viewModel: PagingLibraryViewModel<Library>,
        playButtonItemID: BaseItemDto.ID? = nil,
        @ViewBuilder header: () -> Header = { EmptyView() }
    ) {
        self.viewModel = viewModel
        self.playButtonItemID = playButtonItemID
        self.header = header()
    }

    private var elements: [Element] {
        switch viewModel.state {
        case .content:
            if viewModel.elements.isEmpty {
                [.empty]
            } else {
                viewModel.elements.map { .element($0) }
            }
        case .error:
            viewModel.error.map { error in
                [.error(error)]
            } ?? []
        case .initial, .refreshing:
            Array(repeating: Element.loading, count: 10)
        }
    }

    private var layout: CollectionHStackLayout {
        if UIDevice.isPad {
            .minimumWidth(
                columnWidth: 300,
                rows: 1
            )
        } else {
            .grid(
                columns: 1.5,
                rows: 1,
                columnTrailingInset: 0
            )
        }
    }

    @ViewBuilder
    func _subtitle(episode: BaseItemDto) -> some View {
        if isInParent {
            Text(episode.episodeLocator ?? .emptyDash)
        } else {
            DotHStack {
                if let seriesName = episode.seriesName {
                    Text(seriesName)
                }

                Text(episode.seasonEpisodeLabel ?? .emptyDash)
            }
        }
    }

    @ViewBuilder
    private func _episode(_ episode: BaseItemDto) -> some View {

        var description: String {
            if episode.isUnaired {
                episode.airDateLabel ?? L10n.noOverviewAvailable
            } else {
                episode.overview ?? L10n.noOverviewAvailable
            }
        }

        WithNamespace { namespace in
            ElementView(
                title: episode.displayTitle,
                subtitle: _subtitle(episode: episode),
                description: description
            ) {
                router.route(to: .item(item: episode), in: namespace)
            } content: {
                Button {
                    router.route(
                        to: .videoPlayer(
                            item: episode,
                            queue: EpisodeMediaPlayerQueue(episode: episode)
                        )
                    )
                } label: {
                    ImageView(episode.landscapeImageSources(maxWidth: 200, environment: .init(useParent: false)))
                        .failure {
                            SystemImageContentView(systemName: episode.systemImage)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(.contextMenuPreview, Rectangle())
                        .posterStyle(.landscape)
                        .backport
                        .matchedTransitionSource(id: "item", in: namespace)
                        .posterShadow()
                }
                .foregroundStyle(.primary, .secondary)
            } menuContent: {
                // TODO: get context menu content
                Button("Go to Episode", systemImage: "info.circle") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        router.route(to: .item(item: episode))
                    }
                }

                if !isInParent, let seriesID = episode.seriesID {
                    Button("Go to Show", systemImage: "info.circle") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            router.route(
                                to: .item(
                                    displayTitle: episode.seriesName ?? "",
                                    id: seriesID
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stack: some View {
        CollectionHStack(
            uniqueElements: elements,
            layout: layout
        ) { element in
            switch element {
            case .empty:
                ElementView(
                    title: L10n.noResults,
                    subtitle: .emptyDash,
                    description: L10n.noEpisodesAvailable,
                    action: {}
                )
                .disabled(true)
            case let .error(error):
                ElementView(
                    title: L10n.error,
                    subtitle: .emptyDash,
                    description: error.localizedDescription,
                    systemImage: "arrow.clockwise"
                ) {
                    viewModel.refresh()
                }
            case .loading:
                ElementView(
                    title: String.random(count: 10 ..< 20),
                    subtitle: String.random(count: 7 ..< 12),
                    description: String.random(count: 20 ..< 80),
                    action: {}
                )
                .redacted(reason: .placeholder)
                .disabled(true)
            case let .element(episode):
                _episode(episode)
            }
        }
        .clipsToBounds(false)
        .scrollBehavior(.continuousLeadingEdge)
        .insets(horizontal: EdgeInsets.edgePadding)
        .itemSpacing(EdgeInsets.edgePadding / 2)
        .proxy(proxy)
        .scrollDisabled(viewModel.state != .content)
        .onFirstAppear {
            guard !didScrollToPlayButtonItem else { return }
            didScrollToPlayButtonItem = true
            guard let playButtonItemID else { return }

            // good enough?
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                proxy.scrollTo(id: playButtonItemID, animated: false)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Section {
                stack
            } header: {
                header
            }
        }
    }
}
