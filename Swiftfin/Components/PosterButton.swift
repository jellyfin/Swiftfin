//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// TODO: expose `ImageView.image` modifier for image aspect fill/fit
// TODO: allow `content` to trigger `onSelect`?
// TODO: get width/height for images from layout size?

struct PosterButton<Item: Poster>: View {

    private var item: Item
    private var type: ItemDisplayType
    private var content: () -> any View
    private var imageOverlay: () -> any View
    private var contextMenu: () -> any View
    private var onSelect: () -> Void

    private func imageView(from item: Item) -> ImageView {
        switch type {
        case .narrow:
            ImageView(item.narrowImageSources(maxWidth: 200))
        case .square:
            ImageView(item.squareImageSources(maxWidth: 200))
        case .wide:
            ImageView(item.wideImageSources(maxWidth: 500))
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

                    imageOverlay()
                        .eraseToAnyView()
                }
                .posterStyle(type)
            }
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
        type: ItemDisplayType
    ) {
        self.init(
            item: item,
            type: type,
            content: { TitleContentView(item: item) },
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

// TODO: Shared default content?

extension PosterButton {

    // MARK: Default Content

    struct TitleContentView: View {

        let item: Item

        var body: some View {
            Text(item.displayTitle)
                .font(.footnote.weight(.regular))
                .foregroundColor(.primary)
                .backport
                .lineLimit(1, reservesSpace: true)
        }
    }

//    struct SubtitleContentView: View {
//
//        let item: Item
//
//        var body: some View {
//            Text(item.subtitle ?? "")
//                .font(.caption.weight(.medium))
//                .foregroundColor(.secondary)
//        }
//    }

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
