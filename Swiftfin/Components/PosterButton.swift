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

// TODO: builder methods shouldn't take the item

struct PosterButton<Item: Poster>: View {

    private var item: Item
    private var type: PosterType
    private var content: (Item) -> any View
    private var imageOverlay: (Item) -> any View
    private var contextMenu: (Item) -> any View
    private var onSelect: () -> Void
    private var singleImage: Bool

//    private var itemWidth: CGFloat {
//        type.width * itemScale
//    }

    @ViewBuilder
    private func poster(from item: any Poster) -> some View {
        switch type {
        case .portrait:
            ImageView(item.portraitPosterImageSource(maxWidth: 500))
                .failure {
                    InitialFailureView(item.displayTitle.initials)
                }
        case .landscape:
            ImageView(item.landscapePosterImageSources(maxWidth: 500, single: singleImage))
                .failure {
                    InitialFailureView(item.displayTitle.initials)
                }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Button {
                onSelect()
            } label: {
                ZStack {
                    Color.clear
                    
                    poster(from: item)
                }
                .posterStyle(type)
                .overlay {
                    imageOverlay(item)
                        .eraseToAnyView()
                        .posterStyle(type)
                }
            }
            .contextMenu(menuItems: {
                contextMenu(item)
                    .eraseToAnyView()
            })
            .posterShadow()

            content(item)
                .eraseToAnyView()
        }
    }
}

extension PosterButton {

    init(
        item: Item,
        type: PosterType,
        singleImage: Bool = false
    ) {
        self.init(
            item: item,
            type: type,
            content: { TitleSubtitleContentView(item: $0) },
            imageOverlay: { DefaultOverlay(item: $0) },
            contextMenu: { _ in EmptyView() },
            onSelect: {},
            singleImage: singleImage
        )
    }

    func content(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    func imageOverlay(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.imageOverlay, with: content)
    }

    func contextMenu(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.contextMenu, with: content)
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}

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
            Text(item.subtitle ?? "")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
    }

    struct TitleSubtitleContentView: View {

        private let item: Item
        private let titleLineLimit: Int
        private let subtitleLineLimit: Int
        
        init(
            item: Item,
            titleLineLimit: Int = 1,
            subtitleLineLimit: Int = 1
        ) {
            self.titleLineLimit = titleLineLimit
            self.subtitleLineLimit = subtitleLineLimit
            self.item = item
        }

        var body: some View {
            VStack(alignment: .leading) {
                if item.showTitle {
                    TitleContentView(item: item)
                        .reservingSpaceLineLimit(titleLineLimit)
                }

                SubtitleContentView(item: item)
                    .reservingSpaceLineLimit(subtitleLineLimit)
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
