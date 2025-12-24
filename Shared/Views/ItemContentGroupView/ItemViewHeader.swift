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

struct ItemViewHeader: _ContentGroup {

    let id = "item-view-header"
    let viewModel: _ItemViewModel

    func body(with viewModel: _ItemViewModel) -> Body {
        Body(viewModel: viewModel)
    }

    struct Body: View {

        @Default(.accentColor)
        private var accentColor

        @ObservedObject
        var viewModel: _ItemViewModel

        @Namespace
        private var namespace

        @Router
        private var router

        @ViewBuilder
        private var overlay: some View {
            VStack(alignment: .center, spacing: 10) {
                ZStack(alignment: .bottom) {
                    Color.clear
                        .aspectRatio(1.77, contentMode: .fill)

                    ImageView(viewModel.item.imageURL(.logo, maxHeight: 70))
                        .placeholder { _ in
                            EmptyView()
                        }
                        .failure {
                            MaxHeightText(text: viewModel.item.displayTitle, maxHeight: 70)
                                .font(.largeTitle.weight(.semibold))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 70, alignment: .bottom)
                }
                .frame(maxWidth: .infinity)
                .zIndex(10)

                VStack(alignment: .center, spacing: 10) {
                    DotHStack {
                        if let firstGenre = viewModel.item.genres?.first {
                            Text(firstGenre)
                        }

                        if let premiereYear = viewModel.item.premiereDateYear {
                            Text(premiereYear)
                        }

                        if let runtime = viewModel.item.runtime {
                            Text(runtime, format: .hourMinuteAbbreviated)
                        }
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                    if viewModel.item.presentPlayButton {
                        PlayButton(viewModel: viewModel)
                    }

                    ItemView.OverviewView(item: viewModel.item)
                        .overviewLineLimit(3)
                        .taglineLineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    AttributesHStack(
                        attributes: ItemViewAttribute.allCases,
                        item: viewModel.item,
                        mediaSource: nil
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .edgePadding(.bottom)
                .background(
                    alignment: .bottom,
                    extendedBy: .init(vertical: 25, horizontal: EdgeInsets.edgePadding)
                ) {
                    Rectangle()
                        .fill(Material.ultraThin)
                        .maskLinearGradient {
                            (location: 0, opacity: 0)
                            (location: 0.1, opacity: 0.7)
                            (location: 0.2, opacity: 1)
                        }
                }
                .zIndex(9)
            }
        }

        var body: some View {
            WithEnvironment(value: \.frameForParentView) { frameForParentView in
                var opacity: CGFloat {
                    let end = frameForParentView[.scrollView, default: .zero].safeAreaInsets.top + 25
                    let start = end + 100
                    let offset = frameForParentView[.scrollViewHeader, default: .zero].frame.maxY

                    return clamp((offset - end) / (start - end), min: 0, max: 1)
                }

                VStack {
                    overlay
                        .edgePadding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .colorScheme(.dark)
                }
                .backgroundParallaxHeader(
                    multiplier: 0.3
                ) {
                    AlternateLayoutView {
                        Color.clear
                    } content: {
                        ImageView(
                            viewModel.item.landscapeImageSources(maxWidth: 1320, environment: .init(useParent: false))
                        )
                    }
                    .aspectRatio(1.77, contentMode: .fit)
                }
                .overlay {
                    Color.systemBackground
                        .opacity(1 - opacity)
                }
            }
//            .scrollViewHeaderOffsetOpacity()
            .trackingFrame(for: .scrollViewHeader, key: ScrollViewHeaderFrameKey.self)
            .preference(key: _UseOffsetNavigationBarKey.self, value: true)
            .preference(key: MenuContentKey.self) {
//                if viewModel.userSession.user.permissions.items.canEditMetadata(item: viewModel.item) {
                MenuContentGroup(id: "test") {
                    Button(L10n.edit, systemImage: "pencil") {
                        router.route(to: .editItem(viewModel.item))

//                            router.route(to: .settings)
                    }
                }
//                }
            }
        }
    }
}

extension View {

    func background(
        alignment: Alignment = .center,
        extendedBy insets: EdgeInsets = .init(),
        @ViewBuilder background: () -> some View
    ) -> some View {
        modifier(
            ExtendedBackgroundViewModifier(
                alignment: alignment,
                insets: insets,
                background: background
            )
        )
    }
}

struct ExtendedBackgroundViewModifier<Background: View>: ViewModifier {

    @State
    private var contentFrame: CGRect = .zero

    private let alignment: Alignment
    private let background: Background
    private let insets: EdgeInsets

    init(
        alignment: Alignment,
        insets: EdgeInsets = .init(),
        @ViewBuilder background: () -> Background
    ) {
        self.alignment = alignment
        self.background = background()
        self.insets = insets
    }

    func body(content: Content) -> some View {
        content
            .trackingFrame($contentFrame)
            .background(alignment: alignment) {
                background
                    .frame(
                        width: contentFrame.width + insets.leading + insets.trailing,
                        height: contentFrame.height + insets.top + insets.bottom
                    )
            }
    }
}

struct AttributesHStack: View {

    private let alignment: HorizontalAlignment
    private let attributes: [ItemViewAttribute]
    private let flowDirection: FlowLayout.Direction
    private let item: BaseItemDto
    private let mediaSource: MediaSourceInfo?

    init(
        attributes: [ItemViewAttribute],
        item: BaseItemDto,
        mediaSource: MediaSourceInfo?,
        alignment: HorizontalAlignment = .center,
        flowDirection: FlowLayout.Direction = .up
    ) {
        self.alignment = alignment
        self.attributes = attributes
        self.flowDirection = flowDirection
        self.item = item
        self.mediaSource = mediaSource
    }

    var body: some View {
        if attributes.isNotEmpty {
            FlowLayout(
                alignment: alignment,
                direction: flowDirection
            ) {
                ForEach(attributes, id: \.self) { attribute in
                    switch attribute {
                    case .ratingCritics: CriticRating()
                    case .ratingCommunity: CommunityRating()
                    case .ratingOfficial: OfficialRating()
                    case .videoQuality: VideoQuality()
                    case .audioChannels: AudioChannels()
                    case .subtitles: Subtitles()
                    }
                }
            }
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
    }

    @ViewBuilder
    private func CriticRating() -> some View {
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
    private func CommunityRating() -> some View {
        if let communityRating = item.communityRating {
            AttributeBadge(
                style: .outline,
                title: Text("\(communityRating, specifier: "%.01f")"),
                systemName: "star.fill"
            )
        }
    }

    @ViewBuilder
    private func OfficialRating() -> some View {
        if let officialRating = item.officialRating {
            AttributeBadge(
                style: .outline,
                title: officialRating
            )
        }
    }

    @ViewBuilder
    private func VideoQuality() -> some View {
        if let mediaStreams = mediaSource?.mediaStreams {
            if mediaStreams.has4KVideo {
                AttributeBadge(
                    style: .fill,
                    title: "4K"
                )
            } else if mediaStreams.hasHDVideo {
                AttributeBadge(
                    style: .fill,
                    title: "HD"
                )
            }
            if mediaStreams.hasDolbyVision {
                AttributeBadge(
                    style: .fill,
                    title: "DV"
                )
            }
            if mediaStreams.hasHDRVideo {
                AttributeBadge(
                    style: .fill,
                    title: "HDR"
                )
            }
        }
    }

    @ViewBuilder
    private func AudioChannels() -> some View {
        if let mediaStreams = mediaSource?.mediaStreams {
            if mediaStreams.has51AudioChannelLayout {
                AttributeBadge(
                    style: .fill,
                    title: "5.1"
                )
            }
            if mediaStreams.has71AudioChannelLayout {
                AttributeBadge(
                    style: .fill,
                    title: "7.1"
                )
            }
        }
    }

    @ViewBuilder
    private func Subtitles() -> some View {
        if let mediaStreams = mediaSource?.mediaStreams,
           mediaStreams.hasSubtitles
        {
            AttributeBadge(
                style: .outline,
                title: "CC"
            )
        }
    }
}
