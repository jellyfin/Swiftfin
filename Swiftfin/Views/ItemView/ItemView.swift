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

struct _GenericItemContentView<ViewModel: ObservableObject>: View {

    @ObservedObject
    var viewModel: ViewModel

    var body: some View {}
}

typealias CollectionItemContentView = _GenericItemContentView<CollectionItemViewModel>
typealias MovieItemContentView = _GenericItemContentView<MovieItemViewModel>
typealias SeriesItemContentView = _GenericItemContentView<SeriesItemViewModel>
typealias SimpleItemContentView = _GenericItemContentView<ItemViewModel>

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

// MARK: - ItemGroupProvider

import CollectionHStack

struct AboutItemGroup: _ContentGroup {

    let displayTitle: String
    let id: String

    let item: BaseItemDto

    func body(with viewModel: Empty) -> Body {
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

// MARK: - _ItemViewModel

// MARK: - work

struct FrameForViewPreferenceKey: PreferenceKey {
    static var defaultValue: [CoordinateSpace: CGRect] = [:]

    static func reduce(
        value: inout [CoordinateSpace: CGRect],
        nextValue: () -> [CoordinateSpace: CGRect]
    ) {
        value = nextValue()
    }
}

struct OffsetOpacityModifier: ViewModifier {

    @Environment(\.frameForParentView)
    private var frameForParentView

    private var opacity: CGFloat {
        let end = frameForParentView[.scrollView, default: .zero].safeAreaInsets.top + 50
        let start = end + 100
        let offset = frameForParentView[.scrollViewHeader, default: .zero].frame.maxY

        return min(max((offset - end) / (start - end), 0), 1)
    }

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
    }
}

extension View {

    func backgroundParallaxHeader<Header: View>(
        _ scrollViewOffset: Binding<CGFloat>,
        multiplier: CGFloat = 1,
        @ViewBuilder header: @escaping () -> Header
    ) -> some View {
        modifier(
            aBackgroundParallaxHeaderModifier(
                scrollViewOffset,
                multiplier: multiplier,
                header: header
            )
        )
    }
}

struct aBackgroundParallaxHeaderModifier<Background: View>: ViewModifier {

    @Environment(\.frameForParentView)
    private var frameForParentView

    @Binding
    private var scrollViewOffset: CGFloat

    @State
    private var contentSize: CGSize = .zero
    @State
    private var headerSize: CGSize = .zero

    @State
    private var safeAreaInsetBinding: EdgeInsets = .zero

    private let multiplier: CGFloat
    private let background: Background

    init(
        _ scrollViewOffset: Binding<CGFloat>,
        multiplier: CGFloat = 1,
        @ViewBuilder header: @escaping () -> Background
    ) {
        self._scrollViewOffset = scrollViewOffset
        self.multiplier = multiplier
        self.background = header()
    }

    private var scrollViewSafeAreaInsets: EdgeInsets {
        frameForParentView[.scrollView, default: .zero].safeAreaInsets
    }

    private var maskHeight: CGFloat {
        if scrollViewOffset < 0, abs(scrollViewOffset) >= scrollViewSafeAreaInsets.top {
            contentSize.height + abs(scrollViewOffset)
        } else {
            max(0, contentSize.height + scrollViewSafeAreaInsets.top - offset)
        }
    }

    private var offset: CGFloat {
        let position = scrollViewOffset + frameForParentView[.navigationStack, default: .zero].safeAreaInsets.top

        return if scrollViewOffset < 0, abs(scrollViewOffset) >= scrollViewSafeAreaInsets.top {
            position
        } else {
            position - ((scrollViewOffset + scrollViewSafeAreaInsets.top) * multiplier)
        }
    }

    private var scaleEffect: CGFloat {
        if scrollViewOffset < 0, abs(scrollViewOffset) >= scrollViewSafeAreaInsets.top {
            (headerSize.height + abs(scrollViewOffset + scrollViewSafeAreaInsets.top)) / headerSize.height
        } else {
            1
        }
    }

//        .overlay(alignment: .top) {
//                        VariableBlurView(
//                            maxBlurRadius: 100,
//                            direction: .blurredTopClearBottom,
//                            startOffset: initialHeaderFrame.origin.y
//                        )
//                        .frame(height: initialHeaderFrame.origin.y + 20)
//                        .maskLinearGradient()
//                        .offset(y: -initialHeaderFrame.origin.y)
//                    }

    func body(content: Content) -> some View {
        content
            .trackingSize($contentSize, $safeAreaInsetBinding)
            .background(alignment: .top) {
                MirrorExtensionView(edges: .top) {
                    background
                }
                .trackingSize($headerSize)
                .scaleEffect(scaleEffect, anchor: .top)
                .mask(alignment: .top) {
                    Color.black
                        .frame(height: maskHeight)
                        .offset(y: -scrollViewSafeAreaInsets.top)
                }
                .offset(y: offset)
            }
            .overlay {
                VStack {
                    Text("ScrollView Offset: \(scrollViewOffset)")
                    Text("Background Height: \(headerSize.height)")
                    Text("Safe Area Insets: \(safeAreaInsetBinding.top)")
                    Text("Parent Safe Area Insets: \(scrollViewSafeAreaInsets.top)")

                    Text("--")

                    Text("Background Offset: \(offset)")
                    Text("Mask Height: \(maskHeight)")
                    Text("Scale Effect: \(scaleEffect)")

                    Text("--")

                    Text("NS SA: \(frameForParentView[.navigationStack, default: .zero].safeAreaInsets)")
                }
                .padding()
                .background(Color.white)
                .foregroundStyle(.black)
                .hidden()
            }
    }
}
