//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Logging
import SwiftUI

struct ItemContentGroupView: View {

    @ObservedObject
    private var provider: ItemGroupProvider

    @Default(.Customization.itemViewType)
    private var itemViewType

    @StateObject
    private var viewModel: ContentGroupViewModel<ItemGroupProvider>

    init(provider: ItemGroupProvider) {
        self._provider = ObservedObject(wrappedValue: provider)
        _viewModel = StateObject(wrappedValue: ContentGroupViewModel(provider: provider))
    }

    @ViewBuilder
    private func makeGroupBody(_ group: some ContentGroup) -> some View {
        group.body(with: group.viewModel)
    }

    @ViewBuilder
    private var contentGroupsView: some View {
        VStack(alignment: .leading, spacing: UIDevice.isTV ? 40 : 10) {
            ForEach(viewModel.groups, id: \.id) { group in
                makeGroupBody(group)
                    .eraseToAnyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var contentView: some View {
        let style = ItemContentGroupHeaderStyle.resolve(item: provider.item, itemViewType: itemViewType)
        let header = ItemContentGroupHeaderView(
            style: style,
            item: provider.item,
            localTrailers: provider.localTrailers,
            playButtonItem: provider.playButtonItem,
            selectedMediaSource: provider.selectedMediaSource,
            actions: headerActions
        )

        if style.usesAttachedHeader {
            ItemContentGroupAttachedHeaderScrollView(heightRatio: style.headerHeightRatio) {
                header.attachedBackground
            } overlay: {
                header.attachedOverlay
            } content: {
                belowHeaderContentView(topPadding: 10)
            }
            .refreshable {
                viewModel.refresh()
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: UIDevice.isTV ? 40 : 10) {
                    header

                    belowHeaderContentView(topPadding: 0)
                }
                .edgePadding(.bottom)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .ignoresSafeArea(edges: .horizontal)
            .scrollIndicators(.hidden)
            .refreshable {
                viewModel.refresh()
            }
        }
    }

    private var headerActions: ItemContentGroupHeaderActions {
        .init(
            selectMediaSource: provider.selectMediaSource,
            toggleIsFavorite: {
                Task { await provider.toggleIsFavorite() }
            },
            toggleIsPlayed: {
                Task { await provider.toggleIsPlayed() }
            }
        )
    }

    @ViewBuilder
    private func belowHeaderContentView(topPadding: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: UIDevice.isTV ? 40 : 10) {
            if viewModel.groups.isEmpty {
                ContentUnavailableView(L10n.noResults, systemImage: "rectangle.on.rectangle.slash")
                    .edgePadding(.horizontal)
            } else {
                contentGroupsView
            }
        }
        .padding(.top, topPadding)
        .edgePadding(.bottom)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func navigationMenuButton(for view: some View) -> some View {
        #if os(iOS)
        view.navigationBarMenuButton(
            isLoading: viewModel.background.is(.refreshing),
            isHidden: !provider.item.showEditorMenu
        ) {
            ItemEditorMenu(item: provider.item)
        }
        #else
        view
        #endif
    }

    var body: some View {
        navigationMenuButton(for: ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case .error:
                viewModel.error.map(ErrorView.init)
            case .initial, .refreshing:
                ProgressView()
            }
        })
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.2), value: viewModel.background.states)
        .navigationTitle(provider.displayTitle)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.refresh()
        }
    }
}

private struct ItemContentGroupHeaderActions {
    let selectMediaSource: (MediaSourceInfo) -> Void
    let toggleIsFavorite: () -> Void
    let toggleIsPlayed: () -> Void
}

private enum ItemContentGroupHeaderStyle {
    case enhancedCompact
    case enhancedRegular
    case portrait
    case simple

    static func resolve(item: BaseItemDto, itemViewType: ItemViewType) -> Self {
        if UIDevice.isPad || UIDevice.isTV {
            return .enhancedRegular
        }

        if item.type == .person || item.type == .musicArtist {
            return .portrait
        }

        if itemViewType == .enhanced,
           item.type == .movie || item.type == .series,
           item.backdropImageTags?.isNotEmpty == true
        {
            return .enhancedCompact
        }

        return .simple
    }

    var usesAttachedHeader: Bool {
        switch self {
        case .enhancedCompact, .enhancedRegular:
            true
        case .portrait, .simple:
            false
        }
    }

    var headerHeightRatio: CGFloat {
        switch self {
        case .enhancedCompact:
            0.5
        case .enhancedRegular:
            UIDevice.isTV ? 0.8 : 0.65
        case .portrait, .simple:
            0
        }
    }
}

private struct ItemContentGroupAttachedHeaderScrollView<Background: View, Overlay: View, Content: View>: View {

    @State
    private var safeAreaInsets: EdgeInsets = .zero
    @State
    private var scrollViewOffset: CGFloat = 0
    @State
    private var size: CGSize = .zero

    private let background: Background
    private let content: Content
    private let heightRatio: CGFloat
    private let overlay: Overlay

    init(
        heightRatio: CGFloat,
        @ViewBuilder background: () -> Background,
        @ViewBuilder overlay: () -> Overlay,
        @ViewBuilder content: () -> Content
    ) {
        self.background = background()
        self.content = content()
        self.heightRatio = clamp(heightRatio, min: 0, max: 1)
        self.overlay = overlay()
    }

    private var headerHeight: CGFloat {
        (size.height + safeAreaInsets.vertical) * heightRatio
    }

    private var headerOpacity: CGFloat {
        let start = headerHeight - safeAreaInsets.top - 90
        let end = headerHeight - safeAreaInsets.top - 40
        let diff = end - start

        guard diff != 0 else { return 0 }

        return clamp((scrollViewOffset - start) / diff, min: 0, max: 1)
    }

    private var headerFadeColor: Color {
        #if os(tvOS)
        .black
        #else
        .systemBackground
        #endif
    }

    @ViewBuilder
    private func navigationAdjusted(_ view: some View) -> some View {
        #if os(iOS)
        view.navigationBarOffset(
            $scrollViewOffset,
            start: headerHeight - safeAreaInsets.top - 45,
            end: headerHeight - safeAreaInsets.top - 5
        )
        #else
        view
        #endif
    }

    var body: some View {
        navigationAdjusted(
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    AlternateLayoutView {
                        Color.clear
                            .frame(height: headerHeight, alignment: .bottom)
                    } content: {
                        overlay
                            .frame(height: headerHeight, alignment: .bottom)
                    }
                    .overlay {
                        headerFadeColor
                            .opacity(headerOpacity)
                    }

                    content
                }
            }
            .edgesIgnoringSafeArea(.top)
            .ignoresSafeArea(edges: .horizontal)
            .scrollIndicators(.hidden)
            .trackingSize($size, $safeAreaInsets)
            .scrollViewOffset($scrollViewOffset)
        )
        .backgroundParallaxHeader(
            $scrollViewOffset,
            height: headerHeight,
            multiplier: 0.3
        ) {
            background
                .frame(height: headerHeight)
        }
    }
}

private struct ItemContentGroupHeaderView: View {

    @StoredValue(.User.itemViewAttributes)
    private var attributes

    let style: ItemContentGroupHeaderStyle
    let item: BaseItemDto
    let localTrailers: [BaseItemDto]
    let playButtonItem: BaseItemDto?
    let selectedMediaSource: MediaSourceInfo?
    let actions: ItemContentGroupHeaderActions

    var body: some View {
        switch style {
        case .enhancedCompact, .enhancedRegular:
            attachedOverlay
        case .portrait:
            portraitBody
        case .simple:
            simpleBody
        }
    }

    @ViewBuilder
    var attachedBackground: some View {
        let backdropColor = item.blurHash(for: .backdrop)?.averageLinearColor ?? Color.gray

        AlternateLayoutView {
            Rectangle()
                .fill(backdropColor)
        } content: {
            ImageView(item.landscapeImageSources(maxWidth: 1320, quality: nil))
                .failure {
                    SystemImageContentView(systemName: item.systemImage)
                }
        }
        .aspectRatio(style == .enhancedCompact ? 1.77 : 2, contentMode: .fill)
        .bottomEdgeGradient(bottomColor: backdropColor)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    var attachedOverlay: some View {
        switch style {
        case .enhancedCompact:
            enhancedCompactOverlay
        case .enhancedRegular:
            enhancedRegularOverlay
        case .portrait:
            portraitBody
        case .simple:
            simpleBody
        }
    }

    @ViewBuilder
    private var logo: some View {
        ImageView(item.imageURL(.logo, maxHeight: UIDevice.isTV ? 250 : 90))
            .placeholder { _ in
                EmptyView()
            }
            .failure {
                Text(item.displayTitle)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(UIDevice.isTV ? .largeTitle : .title)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(style == .enhancedRegular ? .leading : .center)
                    .foregroundStyle(.primary)
            }
            .aspectRatio(contentMode: .fit)
            .frame(
                maxWidth: style == .enhancedRegular ? (UIDevice.isTV ? 650 : 420) : .infinity,
                maxHeight: UIDevice.isTV ? 250 : 90,
                alignment: style == .enhancedRegular ? .bottomLeading : .bottom
            )
    }

    @ViewBuilder
    private var metadataView: some View {
        DotHStack {
            if let firstGenre = item.genres?.first {
                Text(firstGenre)
            }

            if let premiereYear = item.premiereDateYear {
                Text(premiereYear)
            }

            if let runtime = playButtonItem?.runTimeLabel ?? item.runTimeLabel {
                Text(runtime)
            }

            if let seasonEpisodeLabel = item.seasonEpisodeLabel {
                Text(seasonEpisodeLabel)
            }
        }
        .font(UIDevice.isTV ? .caption : .caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var actionsView: some View {
//        VStack(alignment: style == .enhancedCompact || style == .simple ? .center : .leading, spacing: 5) {
        VStack(alignment: .center, spacing: 5) {
//            if playButtonItem != nil {
//                ItemContentGroupPlayButton(
//                    item: item,
//                    playButtonItem: playButtonItem,
//                    selectedMediaSource: selectedMediaSource
//                )
//                .frame(height: UIDevice.isTV ? 100 : 50)
//            }

            ItemContentGroupActionButtons(
                item: item,
                localTrailers: localTrailers,
                playButtonItem: playButtonItem,
                selectedMediaSource: selectedMediaSource,
                actions: actions
            )
            .frame(height: UIDevice.isTV ? 100 : 50)
        }
        .frame(maxWidth: UIDevice.isTV ? 450 : 300)
    }

    @ViewBuilder
    private var overviewView: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let tagline = item.taglines?.first, tagline.isNotEmpty {
                Text(tagline)
                    .fontWeight(.bold)
                    .lineLimit(style == .enhancedRegular ? 2 : 2)
            }

            if let overview = item.overview, overview.isNotEmpty {
                Text(overview)
                    .font(.footnote)
                    .lineLimit(style == .enhancedRegular ? 3 : 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var enhancedCompactOverlay: some View {
        VStack(alignment: .center, spacing: 10) {
            AlternateLayoutView(alignment: .bottom) {
                Color.clear
                    .aspectRatio(1.77, contentMode: .fit)
                    .padding(.bottom, 35)
            } content: {
                logo
            }
            .zIndex(10)

            VStack(alignment: .center, spacing: 10) {
                metadataView
                    .padding(.horizontal)

                actionsView

                overviewView

                ItemContentGroupAttributesView(
                    attributes: attributes,
                    item: item,
                    selectedMediaSource: selectedMediaSource
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .edgePadding(.bottom)
            .background(alignment: .bottom) {
                Rectangle()
                    .fill(Material.ultraThin)
                    .maskLinearGradient {
                        (location: 0, opacity: 0)
                        (location: 0.1, opacity: 0.7)
                        (location: 0.2, opacity: 1)
                    }
                    .padding(.horizontal, -EdgeInsets.edgePadding)
                    .padding(.vertical, -25)
            }
            .zIndex(9)
        }
        .edgePadding(.horizontal)
        .frame(maxWidth: .infinity)
        .colorScheme(.dark)
    }

    @ViewBuilder
    private var enhancedRegularOverlay: some View {
        HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
            VStack(alignment: .leading, spacing: UIDevice.isTV ? 20 : 10) {
                logo

                overviewView

                if item.type != .person {
                    FlowLayout(
                        alignment: .leading,
                        direction: .down,
                        spacing: UIDevice.isTV ? 30 : 20,
                        minRowLength: 1
                    ) {
                        metadataView
                            .fixedSize(horizontal: true, vertical: false)

                        ItemContentGroupAttributesView(
                            attributes: attributes,
                            item: item,
                            selectedMediaSource: selectedMediaSource
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            actionsView
        }
        .edgePadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(Material.ultraThin)
                .maskLinearGradient {
                    (location: 0, opacity: 0)
                    (location: 0.5, opacity: 1)
                }
                .padding(.horizontal, -EdgeInsets.edgePadding)
        }
        .colorScheme(.dark)
    }

    @ViewBuilder
    private var portraitBody: some View {
        VStack(spacing: 10) {
            VStack(spacing: 10) {
                HStack(alignment: .bottom, spacing: 12) {
                    PosterImage(
                        item: item,
                        type: .portrait,
                        contentMode: .fit
                    )
                    .withViewContext(.isOverComplexContent)
                    .frame(width: 130)
                    .accessibilityIgnoresInvertColors()
                    .posterShadow()

                    Text(item.displayTitle)
                        .font(.title2)
                        .lineLimit(4)
                        .fontWeight(.semibold)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ItemContentGroupActionButtons(
                    item: item,
                    localTrailers: localTrailers,
                    playButtonItem: playButtonItem,
                    selectedMediaSource: selectedMediaSource,
                    actions: actions
                )
                .frame(maxWidth: 300)
            }
            .frame(maxWidth: 300)

            Divider()

            overviewView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .edgePadding([.bottom, .horizontal])
    }

    @ViewBuilder
    private var simpleBody: some View {
        VStack(spacing: 10) {
            PosterImage(
                item: item,
                type: item.preferredPosterDisplayType == .portrait ? .landscape : item.preferredPosterDisplayType,
                contentMode: .fit
            )
            .frame(maxWidth: item.preferredPosterDisplayType == .square ? 400 : .infinity)
            .accessibilityIgnoresInvertColors()
            .posterShadow()
            .removingViewContext(.isInParent)

            VStack(alignment: .center, spacing: 5) {
                Text(item.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                metadataView
            }

            actionsView

            Divider()

            overviewView

            ItemContentGroupAttributesView(
                attributes: attributes,
                item: item,
                selectedMediaSource: selectedMediaSource
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .edgePadding([.bottom, .horizontal])
        .frame(maxWidth: .infinity)
    }
}

private struct ItemContentGroupPlayButton: View {

    @Default(.accentColor)
    private var accentColor

    @Router
    private var router

    let item: BaseItemDto
    let playButtonItem: BaseItemDto?
    let selectedMediaSource: MediaSourceInfo?

    @State
    private var error: Error?

    private let logger = Logger.swiftfin()

    private var isEnabled: Bool {
        playButtonItem != nil && selectedMediaSource != nil
    }

    private var title: String {
        if item.type == .series,
           let seasonEpisodeLabel = playButtonItem?.seasonEpisodeLabel
        {
            seasonEpisodeLabel
        } else if let playButtonLabel = playButtonItem?.playButtonLabel {
            playButtonLabel
        } else {
            L10n.play
        }
    }

    private var source: String? {
        guard let sourceLabel = selectedMediaSource?.displayTitle,
              playButtonItem?.mediaSources?.count ?? 0 > 1
        else {
            return nil
        }

        return sourceLabel
    }

    var body: some View {
        Button {
            play()
        } label: {
            HStack {
                Image(systemName: "play.fill")

                VStack {
                    Text(title)

                    if let source {
                        Marquee(source, speed: 40, delay: 3, fade: 5)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.horizontal, 20)
            .font(.callout)
            .fontWeight(.semibold)
        }
        .buttonStyle(
            .tintedMaterial(
                tint: UIDevice.isTV ? .white : accentColor,
                foregroundColor: UIDevice.isTV ? .black : accentColor.overlayColor
            )
        )
        .contextMenu {
            if playButtonItem?.userData?.playbackPositionTicks != 0 {
                Button(L10n.playFromBeginning, systemImage: "gobackward") {
                    play(fromBeginning: true)
                }
            }
        }
        .isSelected(true)
        .enabled(isEnabled)
        .errorMessage($error)
    }

    private func play(fromBeginning: Bool = false) {
        guard let playButtonItem,
              let selectedMediaSource
        else {
            logger.error("Play selected with no item or media source")
            error = ErrorMessage(L10n.unknownError)
            return
        }

        let queue: (any MediaPlayerQueue)? = {
            if playButtonItem.type == .episode {
                return EpisodeMediaPlayerQueue(episode: playButtonItem)
            }
            return nil
        }()

        let mediaProvider = MediaPlayerItemProvider(item: playButtonItem) { item in
            try await MediaPlayerItem.build(
                for: item,
                mediaSource: selectedMediaSource
            ) {
                if fromBeginning {
                    $0.userData?.playbackPositionTicks = 0
                }
            }
        }

        router.route(
            to: .videoPlayer(
                provider: mediaProvider,
                queue: queue
            )
        )
    }
}

private struct ItemContentGroupActionButtons: View {

    @StoredValue(.User.enabledTrailers)
    private var enabledTrailers

    let item: BaseItemDto
    let localTrailers: [BaseItemDto]
    let playButtonItem: BaseItemDto?
    let selectedMediaSource: MediaSourceInfo?
    let actions: ItemContentGroupHeaderActions

    private var hasTrailers: Bool {
        if enabledTrailers.contains(.local), localTrailers.isNotEmpty {
            return true
        }

        if enabledTrailers.contains(.external), item.remoteTrailers?.isNotEmpty == true {
            return true
        }

        return false
    }

    var body: some View {
        HStack(alignment: .center, spacing: UIDevice.isTV ? 30 : 10) {
            if item.canBePlayed {
                let isCheckmarkSelected = item.userData?.isPlayed == true

                Button(L10n.played, systemImage: "checkmark") {
                    actions.toggleIsPlayed()
                }
                .buttonStyle(.tintedMaterial(tint: .jellyfinPurple, foregroundColor: .white))
                .isSelected(isCheckmarkSelected)
                .frame(maxWidth: .infinity)
            }

            let isHeartSelected = item.userData?.isFavorite == true

            Button(L10n.favorite, systemImage: isHeartSelected ? "heart.fill" : "heart") {
                actions.toggleIsFavorite()
            }
            .buttonStyle(.tintedMaterial(tint: .red, foregroundColor: .white))
            .isSelected(isHeartSelected)
            .frame(maxWidth: .infinity)

            if let mediaSources = playButtonItem?.mediaSources,
               mediaSources.count > 1
            {
                ItemContentGroupVersionMenu(
                    selectedMediaSource: selectedMediaSource,
                    mediaSources: mediaSources,
                    selectMediaSource: actions.selectMediaSource
                )
                .menuStyle(.button)
                .frame(maxWidth: .infinity)
            }

            if hasTrailers {
                ItemContentGroupTrailerMenu(
                    localTrailers: localTrailers,
                    externalTrailers: item.remoteTrailers ?? []
                )
                .menuStyle(.button)
                .frame(maxWidth: .infinity)
            }

            #if os(tvOS)
            if item.showEditorMenu {
                Menu {
                    ItemEditorMenu(item: item)
                } label: {
                    Label(L10n.advanced, systemImage: "ellipsis")
                        .rotationEffect(.degrees(90))
                }
                .buttonStyle(.material)
                .frame(maxWidth: .infinity)
            }
            #endif
        }
        .font(.title3)
        .fontWeight(.semibold)
        .buttonStyle(.material)
        .labelStyle(.iconOnly)
    }
}

private struct ItemContentGroupVersionMenu: View {

    let selectedMediaSource: MediaSourceInfo?
    let mediaSources: [MediaSourceInfo]
    let selectMediaSource: (MediaSourceInfo) -> Void

    var body: some View {
        Menu(L10n.version, systemImage: "rectangle.stack") {
            ForEach(Array(mediaSources.enumerated()), id: \.offset) { _, mediaSource in
                Button {
                    selectMediaSource(mediaSource)
                } label: {
                    if mediaSource.id == selectedMediaSource?.id {
                        Label(mediaSource.displayTitle, systemImage: "checkmark")
                    } else {
                        Text(mediaSource.displayTitle)
                    }
                }
            }
        }
    }
}

private struct ItemContentGroupTrailerMenu: View {

    @StoredValue(.User.enabledTrailers)
    private var enabledTrailers

    @Router
    private var router

    @State
    private var error: Error?

    let localTrailers: [BaseItemDto]
    let externalTrailers: [NamedURL]
    private let logger = Logger.swiftfin()

    private var showLocalTrailers: Bool {
        enabledTrailers.contains(.local) && localTrailers.isNotEmpty
    }

    private var showExternalTrailers: Bool {
        enabledTrailers.contains(.external) && externalTrailers.isNotEmpty
    }

    var body: some View {
        Group {
            switch localTrailers.count + externalTrailers.count {
            case 1:
                trailerButton
            default:
                trailerMenu
            }
        }
        .errorMessage($error)
    }

    @ViewBuilder
    private var trailerButton: some View {
        Button(
            L10n.trailers,
            systemImage: "movieclapper"
        ) {
            if showLocalTrailers, let firstTrailer = localTrailers.first {
                playLocalTrailer(firstTrailer)
            }

            if showExternalTrailers, let firstTrailer = externalTrailers.first {
                playExternalTrailer(firstTrailer)
            }
        }
    }

    @ViewBuilder
    private var trailerMenu: some View {
        Menu(L10n.trailers, systemImage: "movieclapper") {
            if showLocalTrailers {
                Section(L10n.local) {
                    ForEach(localTrailers) { trailer in
                        Button(
                            trailer.name ?? L10n.trailer,
                            systemImage: "play.fill"
                        ) {
                            playLocalTrailer(trailer)
                        }
                    }
                }
            }

            if showExternalTrailers {
                Section(L10n.external) {
                    ForEach(externalTrailers, id: \.self) { mediaURL in
                        Button(
                            mediaURL.name ?? L10n.trailer,
                            systemImage: "arrow.up.forward"
                        ) {
                            playExternalTrailer(mediaURL)
                        }
                    }
                }
            }
        }
    }

    private func playLocalTrailer(_ trailer: BaseItemDto) {
        if let mediaSource = trailer.mediaSources?.first {
            router.route(to: .videoPlayer(item: trailer, mediaSource: mediaSource))
        } else {
            logger.log(level: .error, "No media sources found")
            error = ErrorMessage(L10n.unknownError)
        }
    }

    private func playExternalTrailer(_ trailer: NamedURL) {
        if let url = URL(string: trailer.url), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                guard !success else { return }

                error = ErrorMessage(L10n.unableToOpenTrailer)
            }
        } else {
            error = ErrorMessage(L10n.unableToOpenTrailer)
        }
    }
}

private struct ItemContentGroupAttributesView: View {

    let attributes: [ItemViewAttribute]
    let item: BaseItemDto
    let selectedMediaSource: MediaSourceInfo?

    var body: some View {
        if attributes.isNotEmpty {
            FlowLayout(
                alignment: .leading,
                direction: .up,
                spacing: UIDevice.isTV ? 20 : 8
            ) {
                ForEach(attributes, id: \.self) { attribute in
                    switch attribute {
                    case .ratingCritics:
                        criticRating
                    case .ratingCommunity:
                        communityRating
                    case .ratingOfficial:
                        officialRating
                    case .videoQuality:
                        videoQuality
                    case .audioChannels:
                        audioChannels
                    case .subtitles:
                        subtitles
                    }
                }
            }
            .foregroundStyle(Color(UIColor.darkGray))
            .lineLimit(1)
        }
    }

    @ViewBuilder
    private var criticRating: some View {
        if let criticRating = item.criticRating {
            AttributeBadge(
                style: .outline,
                title: Text("\(criticRating, specifier: "%.0f")")
            ) {
                if criticRating >= 60 {
                    Image(.tomatoFresh)
                        .symbolRenderingMode(.hierarchical)
                } else {
                    Image(.tomatoRotten)
                }
            }
        }
    }

    @ViewBuilder
    private var communityRating: some View {
        if let communityRating = item.communityRating {
            AttributeBadge(
                style: .outline,
                title: Text("\(communityRating, specifier: "%.01f")"),
                systemName: "star.fill"
            )
        }
    }

    @ViewBuilder
    private var officialRating: some View {
        if let officialRating = item.officialRating {
            AttributeBadge(
                style: .outline,
                title: officialRating
            )
        }
    }

    @ViewBuilder
    private var videoQuality: some View {
        if let mediaStreams = selectedMediaSource?.mediaStreams {
            if mediaStreams.has4KVideo {
                AttributeBadge(style: .fill, title: "4K")
            } else if mediaStreams.hasHDVideo {
                AttributeBadge(style: .fill, title: "HD")
            }

            if mediaStreams.hasDolbyVision {
                AttributeBadge(style: .fill, title: "DV")
            }

            if mediaStreams.hasHDRVideo {
                AttributeBadge(style: .fill, title: "HDR")
            }
        }
    }

    @ViewBuilder
    private var audioChannels: some View {
        if let mediaStreams = selectedMediaSource?.mediaStreams {
            if mediaStreams.has51AudioChannelLayout {
                AttributeBadge(style: .fill, title: "5.1")
            }

            if mediaStreams.has71AudioChannelLayout {
                AttributeBadge(style: .fill, title: "7.1")
            }
        }
    }

    @ViewBuilder
    private var subtitles: some View {
        if let mediaStreams = selectedMediaSource?.mediaStreams,
           mediaStreams.hasSubtitles
        {
            AttributeBadge(style: .outline, title: "CC")
        }
    }
}
