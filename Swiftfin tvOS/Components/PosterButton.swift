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

// TODO: if no context menu defined, don't add context menu

struct PosterButton<Item: Poster>: View {

    @FocusState
    private var isFocused: Bool

    private var item: Item
    private var type: PosterType
    private var itemScale: CGFloat
    private var horizontalAlignment: HorizontalAlignment
    private var content: () -> any View
    private var imageOverlay: () -> any View
    private var contextMenu: () -> any View
    private var onSelect: () -> Void
    private var singleImage: Bool

    // Setting the .focused() modifier causes significant performance issues.
    // Only set if desiring focus changes
    private var onFocusChanged: ((Bool) -> Void)?

    private var itemWidth: CGFloat {
        type.width * itemScale
    }

    var body: some View {
        VStack(alignment: horizontalAlignment) {
            Button {
                onSelect()
            } label: {
                Group {
                    switch type {
                    case .portrait:
                        ImageView(item.portraitPosterImageSource(maxWidth: itemWidth))
                            .failure {
                                InitialFailureView(item.displayTitle.initials)
                            }
                            .posterStyle(type: type, width: itemWidth)
                    case .landscape:
                        ImageView(item.landscapePosterImageSources(maxWidth: itemWidth, single: singleImage))
                            .failure {
                                InitialFailureView(item.displayTitle.initials)
                            }
                            .posterStyle(type: type, width: itemWidth)
                    }
                }
                .overlay {
                    imageOverlay()
                        .eraseToAnyView()
                        .posterStyle(type: type, width: itemWidth)
                }
            }
            .buttonStyle(.card)
            .contextMenu(menuItems: {
                contextMenu()
                    .eraseToAnyView()
            })
            .posterShadow()
            .if(onFocusChanged != nil) { view in
                view
                    .focused($isFocused)
                    .onChange(of: isFocused) { newValue in
                        onFocusChanged?(newValue)
                    }
            }

            content()
                .eraseToAnyView()
                .zIndex(-1)
        }
        .frame(width: itemWidth)
    }
}

extension PosterButton {

    init(item: Item, type: PosterType, singleImage: Bool = false) {
        self.init(
            item: item,
            type: type,
            itemScale: 1,
            horizontalAlignment: .leading,
            content: { DefaultContentView(item: item) },
            imageOverlay: { DefaultOverlay(item: item) },
            contextMenu: { EmptyView() },
            onSelect: {},
            singleImage: singleImage,
            onFocusChanged: nil
        )
    }
}

extension PosterButton {

    func horizontalAlignment(_ alignment: HorizontalAlignment) -> Self {
        copy(modifying: \.horizontalAlignment, with: alignment)
    }

    func scaleItem(_ scale: CGFloat) -> Self {
        copy(modifying: \.itemScale, with: scale)
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

    func onFocusChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onFocusChanged, with: action)
    }
}

// MARK: default content view

extension PosterButton {

    struct DefaultContentView: View {

        let item: Item

        var body: some View {
            VStack(alignment: .leading) {
                if item.showTitle {
                    Text(item.displayTitle)
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }

                if let description = item.subtitle {
                    Text(description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
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
                    if item.userData?.isPlayed ?? false {
                        WatchedIndicator(size: 45)
                            .visible(showPlayed)
                    } else {
                        if (item.userData?.playbackPositionTicks ?? 0) > 0 {
                            ProgressIndicator(progress: (item.userData?.playedPercentage ?? 0) / 100, height: 10)
                                .visible(showProgress)
                        } else {
                            UnwatchedIndicator(size: 45)
                                .foregroundColor(.jellyfinPurple)
                                .visible(showUnplayed)
                        }
                    }

                    if item.userData?.isFavorite ?? false {
                        FavoriteIndicator(size: 45)
                            .visible(showFavorited)
                    }
                }
            }
        }
    }
}
