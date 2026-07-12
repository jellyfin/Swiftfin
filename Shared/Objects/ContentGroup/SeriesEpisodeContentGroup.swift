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

        private enum FocusedSection: Hashable {
            case seasons
            case episodes
        }

        @ObservedObject
        var viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

        #if os(tvOS)
        @FocusState
        private var focusedSeason: PagingLibraryViewModel<EpisodeLibrary>.ID?
        @FocusState
        private var isSeasonPickerFocused: Bool
        #endif

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

        #if os(tvOS)
        private struct SeasonButtonStyle: ButtonStyle {

            @Environment(\.isFocused)
            private var isFocused
            @Environment(\.isSelected)
            private var isSelected

            let isPickerFocused: Bool

            private var isHighlighted: Bool {
                isFocused || (!isPickerFocused && isSelected)
            }

            @ViewBuilder
            private func label(_ configuration: Configuration) -> some View {
                if isHighlighted {
                    configuration.label
                        .foregroundStyle(.black)
                        .labelStyle(
                            CapsuleLabelStyle(
                                tint: .white
                            )
                        )
                } else {
                    configuration.label
                        .foregroundStyle(.primary)
                        .labelStyle(.titleOnly)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
            }

            func makeBody(configuration: Configuration) -> some View {
                label(configuration)
                    .font(.body)
                    .fontWeight(.semibold)
                    .scaleEffect(isFocused ? 1.06 : 1)
                    .shadow(
                        color: isFocused ? .black.opacity(0.5) : .clear,
                        radius: isFocused ? 10 : 0
                    )
                    .animation(.easeInOut(duration: 0.1), value: isFocused)
                    .animation(.easeInOut(duration: 0.1), value: isHighlighted)
            }
        }

        @MainActor
        private func selectSeasonAfterFocusDebounce(
            _ seasonID: PagingLibraryViewModel<EpisodeLibrary>.ID?
        ) async {
            guard let seasonID, seasonID != selection else { return }

            do {
                try await Task.sleep(for: .milliseconds(350))
            } catch {
                return
            }

            guard seasonID == focusedSeason,
                  seasonID != selection,
                  viewModel.elements.contains(where: { $0.id == seasonID })
            else { return }

            selection = seasonID
        }
        #endif

        @ViewBuilder
        private var seasonSelectorView: some View {
            #if os(tvOS)
            if viewModel.elements.isEmpty {
                Text(L10n.episodes)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .edgePadding(.horizontal)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        ForEach(viewModel.elements) { seasonViewModel in
                            let isSelected = selection == seasonViewModel.id

                            Button {
                                selection = seasonViewModel.id
                            } label: {
                                EmptyLabel(seasonViewModel.library.parent.displayTitle)
                            }
                            .buttonStyle(SeasonButtonStyle(isPickerFocused: isSeasonPickerFocused))
                            .isSelected(isSelected)
                            .focused($focusedSeason, equals: seasonViewModel.id)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                    .edgePadding(.horizontal)
                }
                .scrollIndicators(.hidden)
                .backport
                .scrollClipDisabled()
                .focusSection()
                .focused($isSeasonPickerFocused)
                .backport
                .defaultFocus(
                    $focusedSeason,
                    selection ?? preferredSeasonSelection(),
                    priority: .userInitiated
                )
                .task(id: focusedSeason) {
                    await selectSeasonAfterFocusDebounce(focusedSeason)
                }
            }
            #else
            if viewModel.elements.count <= 1 {
                Text(selectedSeasonViewModel?.library.parent.displayTitle ?? L10n.episodes)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .edgePadding(.horizontal)
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
                .labelStyle(
                    CapsuleLabelStyle(
                        isIconTrailing: true
                    )
                )
                .font(.headline)
                .edgePadding(.horizontal)
            }
            #endif
        }

        @ViewBuilder
        var body: some View {
            Group {
                if let selectedSeasonViewModel {
                    _Body(
                        seasonViewModel: selectedSeasonViewModel,
                        playButtonItem: playButtonItem
                    ) {
                        seasonSelectorView
                    }
                } else {
                    LoadingEpisodesView {
                        seasonSelectorView
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

            @FocusState
            private var focusedSection: FocusedSection?
            @FocusState
            private var focusedElement: String?

            let header: Header

            init(@ViewBuilder header: () -> Header) {
                self.header = header()
            }

            private var elements: [_Body<Header>.Element] {
                (0 ..< 10).map(_Body<Header>.Element.loading)
            }

            var body: some View {
                _Body<Header>.collection(
                    elements: elements,
                    focusedSection: $focusedSection,
                    focusedElement: $focusedElement,
                    preferredElementID: elements.first?.id
                ) {
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

            @FocusState
            private var focusedSection: FocusedSection?
            @FocusState
            private var focusedElement: Element.ID?

            let header: Header
            let playButtonItem: BaseItemDto?

            init(
                seasonViewModel: PagingLibraryViewModel<EpisodeLibrary>,
                playButtonItem: BaseItemDto?,
                @ViewBuilder header: () -> Header
            ) {
                self.seasonViewModel = seasonViewModel
                self.playButtonItem = playButtonItem
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

            private var preferredElementID: Element.ID? {
                if let playButtonItemID = playButtonItem?.id,
                   elements.contains(where: { $0.id == playButtonItemID })
                {
                    return playButtonItemID
                }

                return elements.first?.id
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
                focusedSection: FocusState<FocusedSection?>.Binding,
                focusedElement: FocusState<Element.ID?>.Binding,
                preferredElementID: Element.ID?,
                @ViewBuilder header: @escaping () -> some View,
                @ViewBuilder content: @escaping (Element) -> some View
            ) -> some View {
                VStack(alignment: .leading, spacing: 15) {
                    Section {
                        CollectionHStack(
                            uniqueElements: elements,
                            layout: layout
                        ) { element in
                            content(element)
                                .focused(focusedElement, equals: element.id)
                        }
                        .clipsToBounds(false)
                        .insets(horizontal: EdgeInsets.edgePadding)
                        .itemSpacing(itemSpacing)
                        .scrollBehavior(.continuousLeadingEdge)
                        .focusSection()
                        .focused(focusedSection, equals: .episodes)
                        .backport
                        .defaultFocus(
                            focusedElement,
                            preferredElementID,
                            priority: .userInitiated
                        )
                    } header: {
                        header()
                            .focusSection()
                            .focused(focusedSection, equals: .seasons)
                    }
                }
                .focusSection()
                .backport
                .defaultFocus(
                    focusedSection,
                    .episodes,
                    priority: .userInitiated
                )
            }

            var body: some View {
                Self.collection(
                    elements: elements,
                    focusedSection: $focusedSection,
                    focusedElement: $focusedElement,
                    preferredElementID: preferredElementID
                ) {
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

            private enum FocusedElement: Hashable {
                case image
                case content
            }

            @FocusState
            private var focusedElement: FocusedElement?

            @Environment(\.enabledPosterIndicators)
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
                                maxWidth: 250,
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
                    .focused($focusedElement, equals: .image)

                    EpisodeContent(
                        header: episode.displayTitle,
                        subHeader: episode.episodeLocator ?? .emptyDash,
                        content: episodeContent
                    ) {
                        router.route(to: .item(item: episode), in: namespace)
                    }
                    .focused($focusedElement, equals: .content)
                }
                .focusSection()
                .backport
                .defaultFocus(
                    $focusedElement,
                    .image,
                    priority: .userInitiated
                )
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
                            .lineLimit(1)

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

            private enum FocusedElement: Hashable {
                case image
                case content
            }

            @FocusState
            private var focusedElement: FocusedElement?

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
                    .buttonStyle(.card)
                    .focused($focusedElement, equals: .image)

                    EpisodeContent(
                        header: title,
                        subHeader: subHeader,
                        content: content,
                        action: action
                    )
                    .focused($focusedElement, equals: .content)
                }
                .focusSection()
                .backport
                .defaultFocus(
                    $focusedElement,
                    .image,
                    priority: .userInitiated
                )
            }
        }
    }
}
