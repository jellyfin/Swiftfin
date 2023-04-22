//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// TODO: Look at something better for accomadating loading/noResults/other types

struct PosterButton<Item: Poster>: View {

    private var state: PosterButtonType<Item>
    private var type: PosterType
    private var itemScale: CGFloat
    private var horizontalAlignment: HorizontalAlignment
    private var content: (PosterButtonType<Item>) -> any View
    private var imageOverlay: (PosterButtonType<Item>) -> any View
    private var contextMenu: (PosterButtonType<Item>) -> any View
    private var onSelect: () -> Void
    private var singleImage: Bool

    private var itemWidth: CGFloat {
        type.width * itemScale
    }

    @ViewBuilder
    private var loadingPoster: some View {
        Color.secondarySystemFill
            .posterStyle(type: type, width: itemWidth)
    }

    @ViewBuilder
    private var noResultsPoster: some View {
        Color.secondarySystemFill
            .posterStyle(type: type, width: itemWidth)
    }

    @ViewBuilder
    private func poster(from item: any Poster) -> some View {
        Group {
            switch type {
            case .portrait:
                ImageView(item.portraitPosterImageSource(maxWidth: itemWidth))
                    .failure {
                        InitialFailureView(item.displayTitle.initials)
                    }
            case .landscape:
                ImageView(item.landscapePosterImageSources(maxWidth: itemWidth, single: singleImage))
                    .failure {
                        InitialFailureView(item.displayTitle.initials)
                    }
            }
        }
    }

    var body: some View {
        VStack(alignment: horizontalAlignment) {

            Button {
                onSelect()
            } label: {
                Group {
                    switch state {
                    case .loading:
                        loadingPoster
                    case .noResult:
                        noResultsPoster
                    case let .item(item):
                        poster(from: item)
                    }
                }
                .overlay {
                    imageOverlay(state)
                        .eraseToAnyView()
                        .posterStyle(type: type, width: itemWidth)
                }
            }
            .contextMenu(menuItems: {
                contextMenu(state)
                    .eraseToAnyView()
            })
            .posterStyle(type: type, width: itemWidth)
            .posterShadow()

            content(state)
                .eraseToAnyView()
        }
        .frame(width: itemWidth)
    }
}

extension PosterButton {

    init(
        state: PosterButtonType<Item>,
        type: PosterType,
        singleImage: Bool = false
    ) {
        self.init(
            state: state,
            type: type,
            itemScale: 1,
            horizontalAlignment: .leading,
            content: { DefaultContentView(state: $0) },
            imageOverlay: { DefaultOverlay(state: $0) },
            contextMenu: { _ in EmptyView() },
            onSelect: {},
            singleImage: singleImage
        )
    }

    func horizontalAlignment(_ alignment: HorizontalAlignment) -> Self {
        copy(modifying: \.horizontalAlignment, with: alignment)
    }

    func scaleItem(_ scale: CGFloat) -> Self {
        copy(modifying: \.itemScale, with: scale)
    }

    func content(@ViewBuilder _ content: @escaping (PosterButtonType<Item>) -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    func imageOverlay(@ViewBuilder _ content: @escaping (PosterButtonType<Item>) -> any View) -> Self {
        copy(modifying: \.imageOverlay, with: content)
    }

    func contextMenu(@ViewBuilder _ content: @escaping (PosterButtonType<Item>) -> any View) -> Self {
        copy(modifying: \.contextMenu, with: content)
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}

extension PosterButton {

    // MARK: Default Content

    struct DefaultContentView: View {

        let state: PosterButtonType<Item>

        @ViewBuilder
        private var title: some View {
            Group {
                switch state {
                case .loading:
                    String(repeating: "a", count: Int.random(in: 5 ..< 8)).text
                        .redacted(reason: .placeholder)
                case .noResult:
                    L10n.noResults.text
                case let .item(item):
                    if item.showTitle {
                        Text(item.displayTitle)
                    } else {
                        EmptyView()
                    }
                }
            }
            .font(.footnote.weight(.regular))
            .foregroundColor(.primary)
            .lineLimit(2)
        }

        @ViewBuilder
        private var subtitle: some View {
            Group {
                switch state {
                case .loading:
                    String(repeating: "a", count: Int.random(in: 8 ..< 15)).text
                        .redacted(reason: .placeholder)
                case .noResult:
                    L10n.noResults.text
                case let .item(item):
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                    } else {
                        EmptyView()
                    }
                }
            }
            .font(.caption.weight(.medium))
            .foregroundColor(.secondary)
            .lineLimit(2)
        }

        var body: some View {
            VStack(alignment: .leading) {
                title

                subtitle
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

        let state: PosterButtonType<Item>

        var body: some View {
            if case let PosterButtonType.item(item) = state {
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
}
