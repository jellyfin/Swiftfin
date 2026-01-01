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

private let landscapeMaxWidth: CGFloat = 500
private let portraitMaxWidth: CGFloat = 500

struct PosterButton<Item: Poster>: View {

    @EnvironmentTypeValue<Item>(\.posterOverlayRegistry)
    private var posterOverlayRegistry

    @State
    private var posterSize: CGSize = .zero

    private var horizontalAlignment: HorizontalAlignment
    private let item: Item
    private let type: PosterDisplayType
    private let label: any View
    private let action: () -> Void

    @ViewBuilder
    private func poster(overlay: some View) -> some View {
        PosterImage(item: item, type: type)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay { overlay }
            .contentShape(.contextMenuPreview, Rectangle())
            .posterStyle(type)
            .posterShadow()
            .hoverEffect(.highlight)
    }

    var body: some View {
        Button(action: action) {
            let overlay = posterOverlayRegistry?(item) ??
                PosterButton.DefaultOverlay(item: item)
                .eraseToAnyView()

            poster(overlay: overlay)
                .trackingSize($posterSize)

            label
                .eraseToAnyView()
        }
        .buttonStyle(.borderless)
        .buttonBorderShape(.roundedRectangle)
        .focusedValue(\.focusedPoster, AnyPoster(item))
        .accessibilityLabel(item.displayTitle)
        .matchedContextMenu(for: item) {
            EmptyView()
        }
    }
}

extension PosterButton {

    init(
        item: Item,
        type: PosterDisplayType,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> any View
    ) {
        self.item = item
        self.type = type
        self.action = action
        self.label = label()
        self.horizontalAlignment = .leading
    }

    func horizontalAlignment(_ alignment: HorizontalAlignment) -> Self {
        copy(modifying: \.horizontalAlignment, with: alignment)
    }
}

// TODO: Shared default content with iOS?
//       - check if content is generally same

extension PosterButton {

    // MARK: Default Content

    struct TitleContentView: View {

        let item: Item

        var body: some View {
            Text(item.displayTitle)
                .font(.footnote.weight(.regular))
                .foregroundColor(.primary)
                .accessibilityLabel(item.displayTitle)
        }
    }

    struct SubtitleContentView: View {

        let item: Item

        var body: some View {
            Text(item.subtitle ?? "")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
    }

    struct TitleSubtitleContentView: View {

        let item: Item

        var body: some View {
            VStack(alignment: .leading) {
                if item.showTitle {
                    TitleContentView(item: item)
                        .lineLimit(1, reservesSpace: true)
                }

                SubtitleContentView(item: item)
                    .lineLimit(1, reservesSpace: true)
            }
        }
    }

    // TODO: clean up

    // Content specific for BaseItemDto episode items
    struct EpisodeContentSubtitleContent: View {

        let item: Item

        var body: some View {
            if let item = item as? BaseItemDto {
                // Unsure why this needs 0 spacing
                // compared to other default content
                VStack(alignment: .leading, spacing: 0) {
                    if item.showTitle, let seriesName = item.seriesName {
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

            let item: BaseItemDto

            var body: some View {

                SeparatorHStack {
                    Circle()
                        .frame(width: 2, height: 2)
                        .padding(.horizontal, 3)
                } content: {
                    SeparatorHStack {
                        Text(item.seasonEpisodeLabel ?? .emptyDash)

                        if item.showTitle {
                            Text(item.displayTitle)

                        } else if let seriesName = item.seriesName {
                            Text(seriesName)
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
        }
    }

    // TODO: Find better way for these indicators, see EpisodeCard
    struct DefaultOverlay: View {

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
                        WatchedIndicator(size: 45)
                            .isVisible(showPlayed)
                    } else {
                        if (item.userData?.playbackPositionTicks ?? 0) > 0 {
                            ProgressIndicator(progress: (item.userData?.playedPercentage ?? 0) / 100, height: 10)
                                .isVisible(showProgress)
                        } else if item.canBePlayed, !item.isLiveStream {
                            UnwatchedIndicator(size: 45)
                                .foregroundColor(.jellyfinPurple)
                                .isVisible(showUnplayed)
                        }
                    }

                    if item.userData?.isFavorite == true {
                        FavoriteIndicator(size: 45)
                            .isVisible(showFavorited)
                    }
                }
            }
        }
    }
}
