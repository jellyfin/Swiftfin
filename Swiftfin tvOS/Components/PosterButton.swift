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

// TODO: if no context menu defined, don't add context menu

struct PosterButton<Item: Poster>: View {

    @FocusState
    private var isFocused: Bool

    private var item: Item
    private var type: PosterType
    private var horizontalAlignment: HorizontalAlignment
    private var content: () -> any View
    private var imageOverlay: () -> any View
    private var contextMenu: () -> any View
    private var onSelect: () -> Void
    private var singleImage: Bool

    // Setting the .focused() modifier causes significant performance issues.
    // Only set if desiring focus changes
    private var onFocusChanged: ((Bool) -> Void)?

    private func imageView(from item: Item) -> ImageView {
        switch type {
        case .portrait:
            ImageView(item.portraitPosterImageSource(maxWidth: 500))
        case .landscape:
            ImageView(item.landscapePosterImageSources(maxWidth: 500, single: singleImage))
        }
    }

    var body: some View {
        VStack(alignment: horizontalAlignment) {
            Button {
                onSelect()
            } label: {
                ZStack {
                    Color.clear

                    imageView(from: item)
                        .failure {
                            SystemImageContentView(systemName: item.typeSystemImage)
                        }

                    imageOverlay()
                        .eraseToAnyView()
                }
                .posterStyle(type)
            }
            .buttonStyle(.card)
            .contextMenu(menuItems: {
                contextMenu()
                    .eraseToAnyView()
            })
            .posterShadow()
            .ifLet(onFocusChanged) { view, onFocusChanged in
                view
                    .focused($isFocused)
                    .onChange(of: isFocused) { newValue in
                        onFocusChanged(newValue)
                    }
            }

            content()
                .eraseToAnyView()
                .zIndex(-1)
        }
    }
}

extension PosterButton {

    init(item: Item, type: PosterType, singleImage: Bool = false) {
        self.init(
            item: item,
            type: type,
            horizontalAlignment: .leading,
            content: { TitleSubtitleContentView(item: item) },
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

// TODO: Shared default content?

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

        let item: Item

        var body: some View {
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
