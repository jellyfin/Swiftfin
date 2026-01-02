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

struct EpisodeHStack<Library: PagingLibrary>: View where Library.Element == BaseItemDto {

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

    @ObservedObject
    var viewModel: PagingLibraryViewModel<Library>

    @Router
    private var router

    @State
    private var didScrollToPlayButtonItem = false

    @StateObject
    private var proxy = CollectionHStackProxy()

    let playButtonItemID: BaseItemDto.ID?

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
    private func _episode(_ episode: BaseItemDto) -> some View {
        var episodeContent: String {
            if episode.isUnaired {
                episode.airDateLabel ?? L10n.noOverviewAvailable
            } else {
                episode.overview ?? L10n.noOverviewAvailable
            }
        }

        WithNamespace { namespace in
            ElementView(
                title: episode.displayTitle,
                subtitle: episode.episodeLocator ?? .emptyDash,
                description: episodeContent
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
            }
        }
    }

    var body: some View {
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
}
