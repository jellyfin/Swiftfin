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

// TODO: expose `ImageView.image` modifier for image aspect fill/fit

struct PosterButton<Item: Poster>: View {

    @EnvironmentTypeValue<Item>(\.posterOverlayRegistry)
    private var posterOverlayRegistry

    @Namespace
    private var namespace

    @State
    private var posterSize: CGSize = .zero

    private let item: Item
    private let type: PosterDisplayType
    private let label: any View
    private let action: (Namespace.ID) -> Void

    @ViewBuilder
    private func posterView(overlay: some View = EmptyView()) -> some View {
        VStack(alignment: .leading) {
            PosterImage(item: item, type: type)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay { overlay }
                .contentShape(.contextMenuPreview, Rectangle())
                .posterCornerRadius(type)
                .backport
                .matchedTransitionSource(id: "item", in: namespace)
                .posterShadow()

            label
                .eraseToAnyView()
                .allowsHitTesting(false)
        }
    }

    var body: some View {
        Button {
            action(namespace)
        } label: {
            let overlay = posterOverlayRegistry?(item) ??
                PosterButton.DefaultOverlay(item: item)
                .eraseToAnyView()

            posterView(overlay: overlay)
                .trackingSize($posterSize)
        }
        .foregroundStyle(.primary, .secondary)
        .buttonStyle(.plain)
        .matchedContextMenu(for: item) {
            let frameScale = 1.3

            posterView()
                .frame(
                    width: posterSize.width * frameScale,
                    height: posterSize.height * frameScale
                )
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(uiColor: UIColor.secondarySystemGroupedBackground))
                }
        }
    }
}

extension PosterButton {

    init(
        item: Item,
        type: PosterDisplayType,
        action: @escaping (Namespace.ID) -> Void,
        @ViewBuilder label: @escaping () -> any View
    ) {
        self.item = item
        self.type = type
        self.action = action
        self.label = label()
    }
}

// TODO: remove these and replace with `TextStyle`

extension PosterButton {

    // MARK: Default Content

    struct TitleContentView: View {

        let title: String

        var body: some View {
            Text(title)
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundStyle(.primary)
        }
    }

    struct SubtitleContentView: View {

        let subtitle: String?

        var body: some View {
            Text(subtitle ?? " ")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }

    struct TitleSubtitleContentView: View {

        let item: Item

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                if item.showTitle {
                    TitleContentView(title: item.displayTitle)
                        .lineLimit(1, reservesSpace: true)
                }

                SubtitleContentView(subtitle: item.subtitle)
                    .lineLimit(1, reservesSpace: true)
            }
        }
    }

    // Content specific for BaseItemDto episode items
    struct EpisodeContentSubtitleContent: View {

        @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
        private var useSeriesLandscapeBackdrop

        let item: Item

        var body: some View {
            if let item = item as? BaseItemDto {
                // Unsure why this needs 0 spacing
                // compared to other default content
                VStack(alignment: .leading, spacing: 0) {
                    if item.showTitle, let seriesName = item.seriesName {
                        Text(seriesName)
                            .font(.footnote)
                            .fontWeight(.regular)
                            .foregroundColor(.primary)
                            .lineLimit(1, reservesSpace: true)
                    }

                    DotHStack(padding: 3) {
                        Text(item.seasonEpisodeLabel ?? .emptyDash)

                        if item.showTitle || useSeriesLandscapeBackdrop {
                            Text(item.displayTitle)
                        } else if let seriesName = item.seriesName {
                            Text(seriesName)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
            }
        }
    }

    // MARK: Default Overlay

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

        var body: some View {
            ZStack {
                if let item = item as? BaseItemDto {
                    if item.canBePlayed, !item.isLiveStream, item.userData?.isPlayed == true {
                        WatchedIndicator(size: 25)
                            .isVisible(showPlayed)
                    } else {
                        if (item.userData?.playbackPositionTicks ?? 0) > 0 {
                            ProgressIndicator(progress: (item.userData?.playedPercentage ?? 0) / 100, height: 5)
                                .isVisible(showProgress)
                        } else if item.canBePlayed, !item.isLiveStream {
                            UnwatchedIndicator(size: 25)
                                .foregroundColor(accentColor)
                                .isVisible(showUnplayed)
                        }
                    }

                    if item.userData?.isFavorite == true {
                        FavoriteIndicator(size: 25)
                            .isVisible(showFavorited)
                    }
                }
            }
        }
    }
}
