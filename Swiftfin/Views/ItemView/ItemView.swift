//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ItemView: View {

    protocol ScrollContainerView: View {

        associatedtype Content: View

        init(viewModel: ItemViewModel, content: @escaping () -> Content)
    }

    @Default(.Customization.itemViewType)
    private var itemViewType

    @Router
    private var router

    @StateObject
    private var viewModel: ItemViewModel
    @StateObject
    private var deleteViewModel: DeleteItemViewModel

    @State
    private var isPresentingConfirmationDialog = false
    @State
    private var isPresentingEventAlert = false
    @State
    private var error: ErrorMessage?

    // MARK: - Can Delete Item

    private var canDelete: Bool {
        viewModel.userSession.user.permissions.items.canDelete(item: viewModel.item)
    }

    // MARK: - Can Edit Item

    private var canEdit: Bool {
        viewModel.userSession.user.permissions.items.canEditMetadata(item: viewModel.item)
        // TODO: Enable when Subtitle / Lyric Editing is added
        // || viewModel.userSession.user.permissions.items.canManageLyrics(item: viewModel.item)
        // || viewModel.userSession.user.permissions.items.canManageSubtitles(item: viewModel.item)
    }

    // MARK: - Deletion or Editing is Enabled

    private var enableMenu: Bool {
        canEdit || canDelete
    }

    private static func typeViewModel(for item: BaseItemDto) -> ItemViewModel {
        switch item.type {
        case .boxSet, .person, .musicArtist, .tvChannel:
            return CollectionItemViewModel(item: item)
        case .episode:
            return EpisodeItemViewModel(item: item)
        case .movie:
            return MovieItemViewModel(item: item)
        case .musicVideo, .video:
            return ItemViewModel(item: item)
        case .series:
            return SeriesItemViewModel(item: item)
        default:
            assertionFailure("Unsupported item")
            return ItemViewModel(item: item)
        }
    }

    init(item: BaseItemDto) {
        self._viewModel = StateObject(wrappedValue: Self.typeViewModel(for: item))
        self._deleteViewModel = StateObject(wrappedValue: DeleteItemViewModel(item: item))
    }

    @ViewBuilder
    private var scrollContentView: some View {
        switch viewModel.item.type {
        case .boxSet, .person, .musicArtist:
            CollectionItemContentView(viewModel: viewModel as! CollectionItemViewModel)
        case .episode, .musicVideo, .video:
            SimpleItemContentView(viewModel: viewModel)
        case .movie:
            MovieItemContentView(viewModel: viewModel as! MovieItemViewModel)
        case .series:
            SeriesItemContentView(viewModel: viewModel as! SeriesItemViewModel)
        default:
            Text(L10n.notImplementedYetWithType(viewModel.item.type ?? "--"))
        }
    }

    // TODO: break out into pad vs phone views based on item type
    private func scrollContainerView<Content: View>(
        viewModel: ItemViewModel,
        content: @escaping () -> Content
    ) -> any ScrollContainerView {

        if UIDevice.isPad {
            return iPadOSCinematicScrollView(viewModel: viewModel, content: content)
        }

        switch viewModel.item.type {
        case .movie, .series:
            switch itemViewType {
            case .compactPoster:
                return CompactPosterScrollView(viewModel: viewModel, content: content)
            case .compactLogo:
                return CompactLogoScrollView(viewModel: viewModel, content: content)
            case .cinematic:
                return CinematicScrollView(viewModel: viewModel, content: content)
            }
        case .person, .musicArtist:
            return CompactPosterScrollView(viewModel: viewModel, content: content)
        default:
            return SimpleScrollView(viewModel: viewModel, content: content)
        }
    }

    @ViewBuilder
    private var innerBody: some View {
        scrollContainerView(viewModel: viewModel) {
            scrollContentView
        }
        .eraseToAnyView()
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                innerBody
                    .navigationTitle(viewModel.item.displayTitle)
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.send(.refresh)
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .navigationBarMenuButton(
            isLoading: viewModel.backgroundStates.contains(.refresh),
            isHidden: !enableMenu
        ) {
            if canEdit {
                Button(L10n.edit, systemImage: "pencil") {
                    router.route(to: .itemEditor(viewModel: viewModel))
                }
            }

            if canDelete {
                Section {
                    Button(L10n.delete, systemImage: "trash", role: .destructive) {
                        isPresentingConfirmationDialog = true
                    }
                }
            }
        }
        .confirmationDialog(
            L10n.deleteItemConfirmationMessage,
            isPresented: $isPresentingConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button(L10n.confirm, role: .destructive) {
                deleteViewModel.send(.delete)
            }
            Button(L10n.cancel, role: .cancel) {}
        }
        .onReceive(deleteViewModel.events) { event in
            switch event {
            case let .error(eventError):
                error = eventError
                isPresentingEventAlert = true
            case .deleted:
                router.dismiss()
            }
        }
        .alert(
            L10n.error,
            isPresented: $isPresentingEventAlert,
            presenting: error
        ) { _ in
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

import Factory

struct ItemGroupProvider: _ContentGroupProvider {

    let displayTitle: String
    let id: String

    func makeGroups(environment: Void) async throws -> [any _ContentGroup] {

        guard let userSession = Container.shared.currentUserSession() else {
            throw ErrorMessage(L10n.unknownError)
        }

        let item = try await BaseItemDto.getItem(
            id: id,
            userSession: userSession
        )

        return try await _makeGroups(item: item, itemID: id)
    }

    @ContentGroupBuilder
    private func _makeGroups(item: BaseItemDto, itemID: String) async throws -> [any _ContentGroup] {

        if let genres = item.itemGenres, genres.isNotEmpty {
            PillGroup(
                displayTitle: L10n.genres,
                id: "genres",
                library: StaticLibrary(
                    title: L10n.genres,
                    id: "genres",
                    elements: genres
                )
            )
        }

        if let studios = item.itemStudios, studios.isNotEmpty {
            PillGroup(
                displayTitle: L10n.studios,
                id: "studios",
                library: StaticLibrary(
                    title: L10n.studios,
                    id: "studios",
                    elements: studios
                )
            )
        }

        switch item.type {
        case .boxSet, .person, .musicArtist, .tvChannel:
            try await ItemTypeContentGroupProvider(
                itemTypes: BaseItemKind.supportedCases
                    .appending(.episode)
                    .appending(.person),
                parent: item
            )
            .makeGroups(environment: .default)
        default: EmptyContentGroup()
        }

        if let castAndCrew = item.people, castAndCrew.isNotEmpty {
            PosterGroup(
                id: "cast-and-crew",
                library: StaticLibrary(
                    title: L10n.castAndCrew.localizedCapitalized,
                    id: "cast-and-crew",
                    elements: castAndCrew
                ),
                posterDisplayType: .portrait,
                posterSize: .small
            )
        }

        PosterGroup(
            id: "special-features",
            library: SpecialFeaturesLibrary(itemID: itemID),
            posterDisplayType: .landscape,
            posterSize: .small
        )

        PosterGroup(
            id: "similar-items",
            library: SimilarItemsLibrary(itemID: itemID),
            posterDisplayType: .landscape,
            posterSize: .small
        )

        AboutItemGroup(
            displayTitle: L10n.about,
            id: "about",
            item: item
        )
    }
}

import CollectionHStack

struct AboutItemGroup: _ContentGroup {

    let displayTitle: String
    let id: String

    let item: BaseItemDto

    func body(with viewModel: VoidContentGroupViewModel) -> Body {
        Body(item: item)
    }

    struct Body: View {

        private enum AboutViewSection: Identifiable {
            case image
            case overview
            case mediaSource(MediaSourceInfo)
            case ratings

            var id: String? {
                switch self {
                case .image:
                    return "image"
                case .overview:
                    return "overview"
                case let .mediaSource(source):
                    return source.id
                case .ratings:
                    return "ratings"
                }
            }
        }

        @State
        private var contentSize: CGSize = .zero

        @ArrayBuilder<AboutViewSection>
        private var sections: [AboutViewSection] {
//            .image
            .overview

            if let mediaSources = item.mediaSources {
                mediaSources.map(AboutViewSection.mediaSource)
            }

            if item.hasRatings {
                .ratings
            }
        }

        let item: BaseItemDto

        // TODO: break out into a general solution for general use?
        // use similar math from CollectionHStack
        private var padImageWidth: CGFloat {
            let portraitMinWidth: CGFloat = 140
            let contentWidth = contentSize.width
            let usableWidth = contentWidth - EdgeInsets.edgePadding * 2
            var columns = CGFloat(Int(usableWidth / portraitMinWidth))
            let preItemSpacing = (columns - 1) * (EdgeInsets.edgePadding / 2)
            let preTotalNegative = EdgeInsets.edgePadding * 2 + preItemSpacing

            if columns * portraitMinWidth + preTotalNegative > contentWidth {
                columns -= 1
            }

            let itemSpacing = (columns - 1) * (EdgeInsets.edgePadding / 2)
            let totalNegative = EdgeInsets.edgePadding * 2 + itemSpacing
            let itemWidth = (contentWidth - totalNegative) / columns

            return max(0, itemWidth)
        }

        private var phoneImageWidth: CGFloat {
            let contentWidth = contentSize.width
            let usableWidth = contentWidth - EdgeInsets.edgePadding * 2
            let itemSpacing = (EdgeInsets.edgePadding / 2) * 2
            let itemWidth = (usableWidth - itemSpacing) / 3

            return max(0, itemWidth)
        }

        private var cardSize: CGSize {
            let height = UIDevice.isPad ? padImageWidth * 3 / 2 : phoneImageWidth * 3 / 2
            let width = height * 1.65

            return CGSize(width: width, height: height)
        }

        var body: some View {
            VStack(alignment: .leading) {
                Text(L10n.about)
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibility(addTraits: [.isHeader])
                    .edgePadding(.horizontal)

                CollectionHStack(
                    uniqueElements: sections,
                    variadicWidths: true
                ) { section in
                    switch section {
                    case .image:
//                        ImageCard(viewModel: viewModel)
//                            .frame(width: UIDevice.isPad ? padImageWidth : phoneImageWidth)
                        EmptyView()
                    case .overview:
                        ItemView.AboutView.OverviewCard(item: item)
                            .frame(width: cardSize.width, height: cardSize.height)
                    case let .mediaSource(source):
                        ItemView.AboutView.MediaSourcesCard(
                            subtitle: (item.mediaSources ?? []).count > 1 ? source.displayTitle : nil,
                            source: source
                        )
                        .frame(width: cardSize.width, height: cardSize.height)
                    case .ratings:
                        ItemView.AboutView.RatingsCard(item: item)
                            .frame(width: cardSize.width, height: cardSize.height)
                    }
                }
                .clipsToBounds(false)
                .insets(horizontal: EdgeInsets.edgePadding)
                .itemSpacing(EdgeInsets.edgePadding / 2)
                .scrollBehavior(.continuousLeadingEdge)
            }
            .trackingSize($contentSize)
        }
    }
}

@Stateful
class _ItemViewModel: ViewModel, _ContentGroupViewModel {

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.refreshing, then: .content)
            }
        }
    }

    enum State: Hashable {
        case content
        case error
        case initial
        case refreshing
    }

    @Published
    private(set) var item: BaseItemDto = .init()

    init(id: String) {
        self.item = .init(id: id)
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        item = try await item.getFullItem(userSession: userSession)
    }
}

protocol ContentGroupWithHeader: _ContentGroup {}

struct ItemViewHeader: ContentGroupWithHeader {

    let id = "item-view-header"
    let viewModel: _ItemViewModel

    func makeViewModel() -> _ItemViewModel {
        viewModel
    }

    func body(with viewModel: _ItemViewModel) -> Body {
        Body(viewModel: viewModel)
    }

    struct Body: View {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets
        @Environment(\.scrollViewOffset)
        private var scrollViewOffset

        @ObservedObject
        var viewModel: _ItemViewModel

        private var imageType: ImageType {
            switch viewModel.item.type {
            case .episode, .musicVideo, .video:
                .primary
            default:
                .backdrop
            }
        }

        var body: some View {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 300)

                BlurView(style: .systemThinMaterialDark)
                    .maskLinearGradient {
                        (location: 0, opacity: 0)
                        (location: 0.1, opacity: 1)
                    }
                    .frame(height: 200)
            }
            .backgroundParallaxHeader(
                scrollViewOffset,
                height: 0,
                multiplier: 0.3
            ) {
                let bottomColor = viewModel.item.blurHash(for: imageType)?.averageLinearColor ?? Color.secondarySystemFill

                AlternateLayoutView {
                    Color.clear
                } content: {
                    ImageView(viewModel.item.imageSource(imageType, maxWidth: 1320))
                        .aspectRatio(contentMode: .fill)
                }
                .frame(height: 300)
                .bottomEdgeGradient(bottomColor: bottomColor)
            }
            .safeAreaInset(edge: .top, content: { Color.red.frame(height: safeAreaInsets.top) })
        }
    }
}

struct ItemContentGroupView: View {

    @Default(.Customization.itemViewType)
    private var itemViewType

//    @StateObject
//    private var itemViewModel: ItemViewModel
    @StateObject
    private var viewModel: ContentGroupViewModel<ItemGroupProvider>

    init(provider: ItemGroupProvider) {
        _viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
//        _itemViewModel = .init(wrappedValue: .init(item: provider.item))
    }

//    private func scrollContainerView<Content: View>(
//        viewModel: ItemViewModel,
//        content: @escaping () -> Content
//    ) -> any ItemView.ScrollContainerView {
//
//        if UIDevice.isPad {
//            return ItemView.iPadOSCinematicScrollView(viewModel: viewModel, content: content)
//        }
//
//        switch viewModel.item.type {
//        case .movie, .series:
//            switch itemViewType {
//            case .compactPoster:
//                return ItemView.CompactPosterScrollView(viewModel: viewModel, content: content)
//            case .compactLogo:
//                return ItemView.CompactLogoScrollView(viewModel: viewModel, content: content)
//            case .cinematic:
//                return ItemView.CinematicScrollView(viewModel: viewModel, content: content)
//            }
//        case .person, .musicArtist:
//            return ItemView.CompactPosterScrollView(viewModel: viewModel, content: content)
//        default:
//            return ItemView.SimpleScrollView(viewModel: viewModel, content: content)
//        }
//    }

    @ViewBuilder
    private var contentView: some View {
//        scrollContainerView(viewModel: itemViewModel) {
//            VStack(alignment: .leading, spacing: 10) {
//                ContentGroupContentView(viewModel: viewModel)
//            }
//            .edgePadding(.vertical)
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .scrollIndicators(.hidden)
//        .eraseToAnyView()

        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ContentGroupContentView(viewModel: viewModel)
            }
            .edgePadding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .ignoresSafeArea(edges: .horizontal)
        .scrollIndicators(.hidden)
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case .error:
                viewModel.error.map(ErrorView.init)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .backport
        .onChange(of: viewModel.state) { _, newValue in
            print("ContentGroupView: state changed to \(newValue)")
        }
        .backport
        .onChange(of: viewModel.background.states) { oldValue, newValue in
            print("ContentGroupView: background states changed from \(oldValue) to \(newValue)")
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.2), value: viewModel.background.states)
        .navigationTitle(viewModel.provider.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.refresh()
        }
    }
}
