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

extension SeriesEpisodeContentGroup {

    private enum EpisodeElement: Identifiable {

        case empty
        case episode(ItemEntry)
        case error(Error)
        case loading(Int)

        static var loadingElements: [Self] {
            (0 ..< 10).map { .loading($0) }
        }

        var id: String {
            switch self {
            case .empty:
                "empty"
            case let .episode(episode):
                episode.itemID
            case .error:
                "error"
            case let .loading(index):
                "loading-\(index)"
            }
        }
    }

    struct LoadingEpisodesView<Header: View>: View {

        private let header: Header

        init(@ContentBuilder header: () -> Header) {
            self.header = header()
        }

        @ContentBuilder
        var body: some View {
            EpisodeCollectionLayout(
                elements: EpisodeElement.loadingElements,
                preferredElementID: EpisodeElement.loadingElements.first?.id
            ) {
                header
            } content: { element in
                EpisodeElementCard(element: element, refresh: {})
            }
            .scrollDisabled(true)
        }
    }

    struct SeasonEpisodesView<Header: View>: View {

        @OptionalSharedBaseItem
        private var playButtonItem: BaseItemDto?

        private let header: Header
        private let seasonViewModel: PagingLibraryViewModel<EpisodeLibrary>

        init(
            playButtonItem: BaseItemDto?,
            seasonViewModel: PagingLibraryViewModel<EpisodeLibrary>,
            @ContentBuilder header: () -> Header
        ) {
            self.header = header()
            self.playButtonItem = playButtonItem
            self.seasonViewModel = seasonViewModel
        }

        private var elements: [EpisodeElement] {
            switch seasonViewModel.state {
            case .content:
                if seasonViewModel.elements.isEmpty {
                    [.empty]
                } else {
                    seasonViewModel.elements.map(EpisodeElement.episode)
                }

            case .error:
                [seasonViewModel.error.map(EpisodeElement.error) ?? .error(ErrorMessage(L10n.unknownError))]

            case .initial, .refreshing:
                EpisodeElement.loadingElements
            }
        }

        private var preferredElementID: EpisodeElement.ID? {
            if let playButtonItemID = playButtonItem?.id,
               elements.contains(where: { $0.id == playButtonItemID }) {
                return playButtonItemID
            }

            return elements.first?.id
        }

        @ContentBuilder
        var body: some View {
            EpisodeCollectionLayout(
                elements: elements,
                preferredElementID: preferredElementID
            ) {
                header
            } content: { element in
                EpisodeElementCard(element: element) {
                    seasonViewModel.refresh()
                }
            }
            .scrollDisabled(seasonViewModel.state != .content)
        }
    }

    private struct EpisodeCollectionLayout<Header: View, Content: View>: View {

        private enum FocusedSection: Hashable {

            case seasons
            case episodes
        }

        @AdaptiveLayout
        private var viewLayout

        @FocusState
        private var focusedSection: FocusedSection?

        private let elements: [EpisodeElement]
        private let header: Header
        private let preferredElementID: EpisodeElement.ID?
        private let content: (EpisodeElement) -> Content

        init(
            elements: [EpisodeElement],
            preferredElementID: EpisodeElement.ID?,
            @ContentBuilder header: () -> Header,
            @ContentBuilder content: @escaping (EpisodeElement) -> Content
        ) {
            self.content = content
            self.elements = elements
            self.header = header()
            self.preferredElementID = preferredElementID
        }

        private var layout: CollectionHStackLayout {
            .minimumWidth(
                columnWidth: viewLayout.posterMinimumWidth(for: .landscape, size: .medium),
                rows: 1,
                columnFraction: 0.5
            )
        }

        @ContentBuilder
        var body: some View {
            ContentGroupSection {
                CollectionHStack(
                    uniqueElements: elements,
                    layout: layout
                ) { element in
                    content(element)
                        #if os(tvOS)
                            .ignoresSafeArea()
                        #endif
                }
                #if os(tvOS)
                .focusBehavior(initial: .leading, returning: .leading)
                #endif
                .initialElement(id: preferredElementID)
                .clipsToBounds(false)
                .insets(horizontal: viewLayout.edgePadding)
                .itemSpacing(viewLayout.itemSpacing)
                .scrollBehavior(.continuousLeadingEdge)
                .contentInsetAdjustmentBehavior(.never)
                .focusSection()
                .focused($focusedSection, equals: .episodes)
            } header: {
                header
                    .focusSection()
                    .focused($focusedSection, equals: .seasons)
            }
            .focusSection()
            .defaultFocus(
                $focusedSection,
                .episodes,
                priority: .userInitiated
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L10n.seasons)
        }
    }

    private struct EpisodeElementCard: View {

        let element: EpisodeElement
        let refresh: () -> Void

        @ContentBuilder
        var body: some View {
            switch element {
            case .empty:
                EpisodeStateCard(
                    title: L10n.noResults,
                    subHeader: .emptyDash,
                    content: L10n.noEpisodesAvailable,
                    systemImage: nil,
                    action: {}
                )
                .disabled(true)

            case let .episode(episode):
                EpisodeCard(episode: episode.snapshot)

            case let .error(error):
                EpisodeStateCard(
                    title: L10n.error,
                    subHeader: .emptyDash,
                    content: error.localizedDescription,
                    systemImage: "arrow.clockwise",
                    action: refresh
                )

            case .loading:
                EpisodeStateCard(
                    title: String.random(count: 10 ..< 20),
                    subHeader: String.random(count: 7 ..< 12),
                    content: String.random(count: 20 ..< 80),
                    systemImage: nil,
                    action: {}
                )
                .redacted(reason: .placeholder)
                .disabled(true)
            }
        }
    }
}
