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
        case episode(BaseItemDto)
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
                episode.id ?? episode.displayTitle
            case .error:
                "error"
            case let .loading(index):
                "loading-\(index)"
            }
        }
    }

    struct LoadingEpisodesView<Header: View>: View {

        let header: Header

        init(@ViewBuilder header: () -> Header) {
            self.header = header()
        }

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

        @ObservedObject
        var seasonViewModel: PagingLibraryViewModel<EpisodeLibrary>

        let playButtonItem: BaseItemDto?
        let header: Header

        init(
            seasonViewModel: PagingLibraryViewModel<EpisodeLibrary>,
            playButtonItem: BaseItemDto?,
            @ViewBuilder header: () -> Header
        ) {
            self.seasonViewModel = seasonViewModel
            self.playButtonItem = playButtonItem
            self.header = header()
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
               elements.contains(where: { $0.id == playButtonItemID })
            {
                return playButtonItemID
            }

            return elements.first?.id
        }

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

        @FocusState
        private var focusedSection: FocusedSection?
        @FocusState
        private var focusedElement: EpisodeElement.ID?

        let elements: [EpisodeElement]
        let preferredElementID: EpisodeElement.ID?
        let header: Header
        let content: (EpisodeElement) -> Content

        init(
            elements: [EpisodeElement],
            preferredElementID: EpisodeElement.ID?,
            @ViewBuilder header: () -> Header,
            @ViewBuilder content: @escaping (EpisodeElement) -> Content
        ) {
            self.elements = elements
            self.preferredElementID = preferredElementID
            self.header = header()
            self.content = content
        }

        private static var layout: CollectionHStackLayout {
            #if os(tvOS)
            .grid(
                columns: 3.5,
                rows: 1,
                columnTrailingInset: 0
            )
            #else
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
            #endif
        }

        private static var itemSpacing: CGFloat {
            #if os(tvOS)
            40
            #else
            EdgeInsets.edgePadding / 2
            #endif
        }

        var body: some View {
            ContentGroupSection {
                CollectionHStack(
                    uniqueElements: elements,
                    layout: Self.layout
                ) { element in
                    content(element)
                        .focused($focusedElement, equals: element.id)
                }
                .clipsToBounds(false)
                .insets(horizontal: EdgeInsets.edgePadding)
                .itemSpacing(Self.itemSpacing)
                .scrollBehavior(.continuousLeadingEdge)
                .focusSection()
                .focused($focusedSection, equals: .episodes)
                .backport
                .defaultFocus(
                    $focusedElement,
                    preferredElementID,
                    priority: .userInitiated
                )
            } header: {
                header
                    .focusSection()
                    .focused($focusedSection, equals: .seasons)
            }
            .focusSection()
            .backport
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

        @ViewBuilder
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
                EpisodeCard(episode: episode)
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
