//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct PosterButton<Item: Poster>: View {

    @Namespace
    private var namespace

    @State
    private var posterSize: CGSize = .zero

    private let action: (Namespace.ID) -> Void
    private let displayType: PosterDisplayType
    private let item: Item

    init(
        item: Item,
        type: PosterDisplayType,
        action: @escaping (Namespace.ID) -> Void
    ) {
        self.action = action
        self.displayType = type
        self.item = item
    }

    @ViewBuilder
    private func posterImage(overlay: some View) -> some View {
//        #if os(tvOS)
//        PosterImage(item: item, type: displayType)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .overlay { overlay }
//            .contentShape(.contextMenuPreview, Rectangle())
//            .posterStyle(displayType)
//            .posterShadow()
//            .hoverEffect(.highlight)
//        #else
//        PosterImage(item: item, type: displayType)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .overlay { overlay }
//            .contentShape(.contextMenuPreview, Rectangle())
//            .posterCornerRadius(displayType)
//            .backport
//            .matchedTransitionSource(id: "item", in: namespace)
//            .posterShadow()
//        #endif

        PosterImage(
            item: item,
            type: displayType
        )
        .overlay { overlay.posterStyle(displayType) }
        .contentShape(.contextMenuPreview, Rectangle())
        .backport
        .matchedTransitionSource(id: "item", in: namespace)
        .posterShadow()
        .hoverEffect(.highlight)
    }

    @ViewBuilder
    private func buttonLabel(overlay: some View = EmptyView()) -> some View {
        VStack(alignment: .leading) {
            posterImage(overlay: overlay)

            item.posterLabel
                .allowsHitTesting(false)
        }
    }

    var body: some View {
        Button {
            action(namespace)
        } label: {
            // Layout required for tvOS focused offset label behavior
            #if os(tvOS)
            posterImage(overlay: item.posterOverlay(for: displayType))

            item.posterLabel
                .frame(maxWidth: .infinity, alignment: .leading)
            #else
            buttonLabel(overlay: item.posterOverlay(for: displayType))
                .trackingSize($posterSize)
            #endif
        }
        .foregroundStyle(.primary, .secondary)
        .buttonStyle(.borderless)
        .buttonBorderShape(.roundedRectangle)
        .focusedValue(\.focusedPoster, AnyPoster(item))
//        .buttonStyle(.plain)
//        .matchedContextMenu(for: item) {
//            let frameScale = 1.3
//
//            posterView()
//                .frame(
//                    width: posterSize.width * frameScale,
//                    height: posterSize.height * frameScale
//                )
//                .padding(20)
//                .background {
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(Color(uiColor: UIColor.secondarySystemGroupedBackground))
//                }
//        }
//        #endif
    }
}

extension PosterButton {

    // MARK: Default Content

    struct TitleContentView: View {

        let item: Item

        var body: some View {
            Text(item.displayTitle)
                .font(.footnote)
                .foregroundColor(.primary)
                .accessibilityLabel(item.displayTitle)
        }
    }

    struct SubtitleContentView: View {

        let item: Item

        var body: some View {
            Text(item.subtitle ?? " ")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }

    struct TitleSubtitleContentView: View {

        @Default(.Customization.showPosterLabels)
        private var showPosterLabels

        let item: Item

        private var showsTitle: Bool {
            guard let item = item as? BaseItemDto else { return true }

            return switch item.type {
            case .episode, .series, .movie, .boxSet, .collectionFolder:
                showPosterLabels
            default:
                true
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                if showsTitle {
                    TitleContentView(item: item)
                        .lineLimit(1, reservesSpace: true)
                }

                SubtitleContentView(item: item)
                    .lineLimit(1, reservesSpace: true)
            }
        }
    }

    struct EpisodeContentSubtitleContent: View {

        #if os(iOS)
        @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
        private var useSeriesLandscapeBackdrop
        #endif

        @Default(.Customization.showPosterLabels)
        private var showPosterLabels

        let item: Item

        var body: some View {
            if let item = item as? BaseItemDto {
                VStack(alignment: .leading, spacing: 0) {
                    if showPosterLabels, let seriesName = item.seriesName {
                        Text(seriesName)
                            .font(.footnote.weight(.regular))
                            .foregroundColor(.primary)
                            .lineLimit(1, reservesSpace: true)
                    }

                    Subtitle(item: item)
                }
            }
        }

        struct Subtitle: View {

            #if os(iOS)
            @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
            private var useSeriesLandscapeBackdrop
            #endif

            @Default(.Customization.showPosterLabels)
            private var showPosterLabels

            let item: BaseItemDto

            var body: some View {
                SeparatorHStack {
                    Circle()
                        .frame(width: 2, height: 2)
                        .padding(.horizontal, 3)
                } content: {
                    SeparatorHStack {
                        Text(item.seasonEpisodeLabel ?? .emptyDash)

                        #if os(iOS)
                        if showPosterLabels || useSeriesLandscapeBackdrop {
                            Text(item.displayTitle)
                        } else if let seriesName = item.seriesName {
                            Text(seriesName)
                        }
                        #else
                        if showPosterLabels {
                            Text(item.displayTitle)
                        } else if let seriesName = item.seriesName {
                            Text(seriesName)
                        }
                        #endif
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
        }
    }

    // MARK: Default Overlay

    struct SelectionOverlay: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected

        var body: some View {
            if isSelected {
                ContainerRelativeShape()
                    .stroke(accentColor, lineWidth: UIDevice.isTV ? 12 : 8)
                    .clipped()
            }
        }
    }

    struct DefaultOverlay: View {

        @Default(.accentColor)
        private var accentColor
        @Default(.Customization.Indicators.showFavorited)
        private var showFavorited
        @Default(.Customization.Indicators.showProgress)
        private var showProgress
        @Default(.Customization.Indicators.showUnplayed)
        private var showUnplayed
        @Default(.Customization.Indicators.showPlayed)
        private var showPlayed

        let item: Item

        private var indicatorSize: CGFloat {
            #if os(tvOS)
            45
            #else
            25
            #endif
        }

        private var progressHeight: CGFloat {
            #if os(tvOS)
            10
            #else
            5
            #endif
        }

        var body: some View {
            ZStack {
                SelectionOverlay()

                if let item = item as? BaseItemDto {
                    if item.canBePlayed, !item.isLiveStream, item.userData?.isPlayed == true {
                        WatchedIndicator(size: indicatorSize)
                            .isVisible(showPlayed)
                    } else {
                        if (item.userData?.playbackPositionTicks ?? 0) > 0 {
                            ProgressIndicator(progress: (item.userData?.playedPercentage ?? 0) / 100, height: progressHeight)
                                .isVisible(showProgress)
                        } else if item.canBePlayed,
                                  !item.isLiveStream,
                                  showUnplayed != .none
                        {
                            UnwatchedIndicator(
                                size: indicatorSize,
                                count:
                                showUnplayed == .count ? item.userData?.unplayedItemCount : nil
                            )
                            .foregroundStyle(accentColor.overlayColor, accentColor)
                        }
                    }

                    if item.userData?.isFavorite == true {
                        FavoriteIndicator(size: indicatorSize)
                            .isVisible(showFavorited)
                    }
                }
            }
        }
    }
}
