//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import JellyfinAPI
import SwiftUI

struct SeriesEpisodeContentGroup: ContentGroup, Identifiable {

    let id: String
    let playButtonItem: BaseItemDto?
    let series: BaseItemDto
    let viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

    var displayTitle: String {
        L10n.episodes
    }

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty
    }

    init(
        series: BaseItemDto,
        playButtonItem: BaseItemDto? = nil
    ) {
        self.id = "\(series.id ?? "series")-episode-selector"
        self.playButtonItem = playButtonItem
        self.series = series
        self.viewModel = .init(library: SeasonViewModelLibrary(series: series), pageSize: 100)
    }

    func body(with viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>) -> Body {
        Body(
            viewModel: viewModel,
            playButtonItem: playButtonItem
        )
    }

    struct Body: View {

        @ObservedObject
        var viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

        let playButtonItem: BaseItemDto?

        @State
        private var selection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        private var selectedSeasonViewModel: PagingLibraryViewModel<EpisodeLibrary>? {
            viewModel.elements.first { $0.id == selection }
        }

        private func preferredSeasonSelection() -> PagingLibraryViewModel<EpisodeLibrary>.ID? {
            if let playButtonSeasonID = playButtonItem?.seasonID,
               viewModel.elements.contains(where: { $0.id == playButtonSeasonID })
            {
                return playButtonSeasonID
            }

            return viewModel.elements.first?.id
        }

        private func selectPreferredSeasonIfNeeded() {
            if selection == nil || !viewModel.elements.contains(where: { $0.id == selection }) {
                selection = preferredSeasonSelection()
            }
        }

        private func refreshSelectedSeasonIfNeeded() {
            guard let selectedSeasonViewModel, selectedSeasonViewModel.state == .initial else { return }
            selectedSeasonViewModel.refresh()
        }

        @ViewBuilder
        private var seasonSelectorView: some View {
            if viewModel.elements.count <= 1 {
                Text(selectedSeasonViewModel?.library.parent.displayTitle ?? L10n.episodes)
                    .font(.title2)
                    .fontWeight(.semibold)
            } else {
                Menu(
                    selectedSeasonViewModel?.library.parent.displayTitle ?? L10n.episodes,
                    systemImage: "chevron.down"
                ) {
                    Picker(L10n.seasons, selection: $selection) {
                        ForEach(viewModel.elements) { seasonViewModel in
                            Text(seasonViewModel.library.parent.displayTitle)
                                .tag(seasonViewModel.id)
                        }
                    }
                }
                #if os(iOS)
                .labelStyle(
                    CapsuleLabelStyle(
                        insets: .init(vertical: 5, horizontal: 10),
                        isIconTrailing: true
                    )
                )
                .font(.headline)
                #endif
            }
        }

        @ViewBuilder
        var body: some View {
            Group {
                if let selectedSeasonViewModel {
                    _Body(seasonViewModel: selectedSeasonViewModel) {
                        seasonSelectorView
                            .edgePadding(.horizontal)
                    }
                } else {
                    LoadingEpisodesView {
                        seasonSelectorView
                            .edgePadding(.horizontal)
                    }
                }
            }
            .onFirstAppear {
                selectPreferredSeasonIfNeeded()
                refreshSelectedSeasonIfNeeded()
            }
            .backport
            .onChange(of: viewModel.elements.count) {
                selectPreferredSeasonIfNeeded()
            }
            .backport
            .onChange(of: selection) {
                refreshSelectedSeasonIfNeeded()
            }
        }

        private struct LoadingEpisodesView<Header: View>: View {

            let header: Header

            init(@ViewBuilder header: () -> Header) {
                self.header = header()
            }

            private var elements: [_Body<Header>.Element] {
                (0 ..< 10).map(_Body<Header>.Element.loading)
            }

            var body: some View {
                _Body<Header>.collection(elements: elements) {
                    header
                } content: { _ in
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
                .scrollDisabled(true)
            }
        }

        private struct _Body<Header: View>: View {

            enum Element: Identifiable {
                case empty
                case episode(BaseItemDto)
                case error(Error)
                case loading(Int)

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

            @ObservedObject
            var seasonViewModel: PagingLibraryViewModel<EpisodeLibrary>

            let header: Header

            init(
                seasonViewModel: PagingLibraryViewModel<EpisodeLibrary>,
                @ViewBuilder header: () -> Header
            ) {
                self.seasonViewModel = seasonViewModel
                self.header = header()
            }

            private var elements: [Element] {
                switch seasonViewModel.state {
                case .content:
                    if seasonViewModel.elements.isEmpty {
                        [.empty]
                    } else {
                        seasonViewModel.elements.map(Element.episode)
                    }
                case .error:
                    [seasonViewModel.error.map(Element.error) ?? .error(ErrorMessage(L10n.unknownError))]
                case .initial, .refreshing:
                    (0 ..< 10).map(Element.loading)
                }
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

            static func collection(
                elements: [Element],
                @ViewBuilder header: @escaping () -> some View,
                @ViewBuilder content: @escaping (Element) -> some View
            ) -> some View {
                VStack(alignment: .leading, spacing: 20) {
                    Section {
                        CollectionHStack(
                            uniqueElements: elements,
                            layout: layout
                        ) { element in
                            content(element)
                        }
                        .clipsToBounds(false)
                        .insets(horizontal: EdgeInsets.edgePadding)
                        .itemSpacing(itemSpacing)
                        .scrollBehavior(.continuousLeadingEdge)
                    } header: {
                        header()
                    }
                }
            }

            var body: some View {
                Self.collection(elements: elements) {
                    header
                } content: { element in
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
                            systemImage: "arrow.clockwise"
                        ) {
                            seasonViewModel.refresh()
                        }
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
                .scrollDisabled(seasonViewModel.state != .content)
            }
        }

        private struct EpisodeCard: View {

            @Default(.Customization.Indicators.enabled)
            private var indicators

            @Namespace
            private var namespace

            @Router
            private var router

            let episode: BaseItemDto

            @ViewBuilder
            private var overlayView: some View {
                if indicators.contains(.progress), let progressLabel = episode.progressLabel {
                    ProgressIndicator(
                        title: progressLabel,
                        progress: (episode.userData?.playedPercentage ?? 0) / 100,
                        posterDisplayType: .landscape
                    )
                } else if indicators.contains(.played), episode.userData?.isPlayed ?? false {
                    PlayedIndicator()
                        .frame(width: UIDevice.isTV ? 45 : 25, height: UIDevice.isTV ? 45 : 25)
                        .padding(3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }

            private var episodeContent: String {
                if episode.isUnaired {
                    episode.airDateLabel ?? L10n.noOverviewAvailable
                } else {
                    episode.overview ?? L10n.noOverviewAvailable
                }
            }

            var body: some View {
                VStack(alignment: .leading) {
                    Button {
                        router.route(
                            to: .videoPlayer(
                                item: episode,
                                queue: EpisodeMediaPlayerQueue(episode: episode)
                            )
                        )
                    } label: {
                        ImageView(episode.landscapeImageSources(
                            environment: .init(
                                maxWidth: UIDevice.isTV ? 500 : 250,
                                useParent: false
                            )
                        ))
                        .failure {
                            SystemImageContentView(systemName: episode.systemImage)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay {
                            overlayView
                        }
                        .contentShape(.contextMenuPreview, Rectangle())
                        .posterStyle(.landscape)
                        .posterShadow()
                        .backport
                        .matchedTransitionSource(id: "item", in: namespace)
                    }
                    .buttonStyle(.card)

                    EpisodeContent(
                        header: episode.displayTitle,
                        subHeader: episode.episodeLocator ?? .emptyDash,
                        content: episodeContent
                    ) {
                        router.route(to: .item(item: episode), in: namespace)
                    }
                }
            }
        }

        private struct EpisodeContent: View {

            let header: String
            let subHeader: String
            let content: String
            let action: () -> Void

            var body: some View {
                Button(action: action) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subHeader)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(header)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        SeeMoreText(content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3, reservesSpace: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }

        private struct EpisodeStateCard: View {

            let title: String
            let subHeader: String
            let content: String
            let systemImage: String?
            let action: () -> Void

            var body: some View {
                VStack(alignment: .leading) {
                    Button(action: action) {
                        Rectangle()
                            .fill(.complexSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay {
                                if let systemImage {
                                    RelativeSystemImageView(systemName: systemImage)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .posterStyle(.landscape)
                            .posterShadow()
                    }
                    #if os(tvOS)
                    .buttonStyle(.card)
                    #endif

                    EpisodeContent(
                        header: title,
                        subHeader: subHeader,
                        content: content,
                        action: action
                    )
                }
            }
        }
    }
}
