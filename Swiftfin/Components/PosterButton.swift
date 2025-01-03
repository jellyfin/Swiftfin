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
// TODO: allow `content` to trigger `onSelect`?
//       - not in button label to avoid context menu visual oddities
// TODO: why don't shadows work with failure image views?
//       - due to `Color`?

/// Retrieving images by exact pixel dimensions is a bit
/// intense for normal usage and eases cache usage and modifications.
private let landscapeMaxWidth: CGFloat = 200
private let portraitMaxWidth: CGFloat = 200

struct PosterButton<Item: Poster>: View {

    private var item: Item
    private var type: PosterDisplayType
    private var content: () -> any View
    private var imageOverlay: () -> any View
    private var contextMenu: () -> any View
    private var onSelect: () -> Void

    private func imageView(from item: Item) -> ImageView {
        switch type {
        case .landscape:
            ImageView(item.landscapeImageSources(maxWidth: landscapeMaxWidth))
        case .portrait:
            ImageView(item.portraitImageSources(maxWidth: portraitMaxWidth))
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Button {
                onSelect()
            } label: {
                ZStack {
                    Color.clear

                    imageView(from: item)
                        .failure {
                            if item.showTitle {
                                SystemImageContentView(systemName: item.systemImage)
                            } else {
                                SystemImageContentView(
                                    title: item.displayTitle,
                                    systemName: item.systemImage
                                )
                            }
                        }

                    imageOverlay()
                        .eraseToAnyView()
                }
                .posterStyle(type)
            }
            .buttonStyle(.plain)
            .contextMenu(menuItems: {
                contextMenu()
                    .eraseToAnyView()
            })
            .posterShadow()

            content()
                .eraseToAnyView()
        }
    }
}

extension PosterButton {

    init(
        item: Item,
        type: PosterDisplayType
    ) {
        self.init(
            item: item,
            type: type,
            content: { TitleSubtitleContentView(item: item) },
            imageOverlay: { DefaultOverlay(item: item) },
            contextMenu: { EmptyView() },
            onSelect: {}
        )
    }

    func content(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    func imageOverlay(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.imageOverlay, with: content)
    }

    func contextMenu(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.contextMenu, with: content)
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}

// TODO: Shared default content with tvOS?
//       - check if content is generally same

extension PosterButton {

    // MARK: Default Content

    struct TitleContentView: View {

        let item: Item

        var body: some View {
            Text(item.displayTitle)
                .font(.footnote.weight(.regular))
                .foregroundColor(.primary)
        }
    }

    struct SubtitleContentView: View {

        let item: Item

        var body: some View {
            Text(item.subtitle ?? " ")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
    }

    struct TitleSubtitleContentView: View {

        let item: Item

        var body: some View {
            iOS15View {
                VStack(alignment: .leading, spacing: 0) {
                    if item.showTitle {
                        TitleContentView(item: item)
                            .backport
                            .lineLimit(1, reservesSpace: true)
                            .iOS15 { v in
                                v.font(.footnote.weight(.regular))
                            }
                    }

                    SubtitleContentView(item: item)
                        .backport
                        .lineLimit(1, reservesSpace: true)
                        .iOS15 { v in
                            v.font(.caption.weight(.medium))
                        }
                }
            } content: {
                VStack(alignment: .leading) {
                    if item.showTitle {
                        TitleContentView(item: item)
                            .backport
                            .lineLimit(1, reservesSpace: true)
                    }

                    SubtitleContentView(item: item)
                        .backport
                        .lineLimit(1, reservesSpace: true)
                }
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
                            .font(.footnote.weight(.regular))
                            .foregroundColor(.primary)
                            .backport
                            .lineLimit(1, reservesSpace: true)
                    }

                    SeparatorHStack {
                        Text(item.seasonEpisodeLabel ?? .emptyDash)

                        if item.showTitle || useSeriesLandscapeBackdrop {
                            Text(item.displayTitle)
                        } else if let seriesName = item.seriesName {
                            Text(seriesName)
                        }
                    }
                    .separator {
                        Circle()
                            .frame(width: 2, height: 2)
                            .padding(.horizontal, 3)
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
                    if item.userData?.isPlayed ?? false {
                        WatchedIndicator(size: 25)
                            .visible(showPlayed)
                    } else {
                        if (item.userData?.playbackPositionTicks ?? 0) > 0 {
                            ProgressIndicator(progress: (item.userData?.playedPercentage ?? 0) / 100, height: 5)
                                .visible(showProgress)
                        } else {
                            UnwatchedIndicator(size: 25)
                                .foregroundColor(accentColor)
                                .visible(showUnplayed)
                        }
                    }

                    if item.userData?.isFavorite ?? false {
                        FavoriteIndicator(size: 25)
                            .visible(showFavorited)
                    }
                }
            }
        }
    }
}
