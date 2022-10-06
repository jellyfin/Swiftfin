//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Look at something better for accomadating loading/noResults/other types

struct PosterButton<Item: Poster, Content: View, ImageOverlay: View, ContextMenu: View>: View {

    private var state: PosterButtonType<Item>
    private var type: PosterType
    private var itemScale: CGFloat
    private var horizontalAlignment: HorizontalAlignment
    private var content: (PosterButtonType<Item>) -> Content
    private var imageOverlay: (PosterButtonType<Item>) -> ImageOverlay
    private var contextMenu: (PosterButtonType<Item>) -> ContextMenu
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
    private func poster(from item: Item) -> some View {
        Group {
            switch type {
            case .portrait:
                ImageView(item.portraitPosterImageSource(maxWidth: itemWidth))
                    .failure {
                        InitialFailureView(item.displayName.initials)
                    }
            case .landscape:
                ImageView(item.landscapePosterImageSources(maxWidth: itemWidth, single: singleImage))
                    .failure {
                        InitialFailureView(item.displayName.initials)
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
                        .posterStyle(type: type, width: itemWidth)
                }
            }
            .contextMenu(menuItems: {
                contextMenu(state)
            })
            .posterStyle(type: type, width: itemWidth)
            .posterShadow()

            content(state)
        }
        .frame(width: itemWidth)
    }
}

extension PosterButton where Content == PosterButtonDefaultContentView<Item>,
    ImageOverlay == EmptyView,
    ContextMenu == EmptyView
{

    init(state: PosterButtonType<Item>, type: PosterType, singleImage: Bool = false) {
        self.init(
            state: state,
            type: type,
            itemScale: 1,
            horizontalAlignment: .leading,
            content: { PosterButtonDefaultContentView(state: $0) },
            imageOverlay: { _ in EmptyView() },
            contextMenu: { _ in EmptyView() },
            onSelect: {},
            singleImage: singleImage
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

    func content<C: View>(@ViewBuilder _ content: @escaping (PosterButtonType<Item>) -> C)
    -> PosterButton<Item, C, ImageOverlay, ContextMenu> {
        .init(
            state: state,
            type: type,
            itemScale: itemScale,
            horizontalAlignment: horizontalAlignment,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            onSelect: onSelect,
            singleImage: singleImage
        )
    }

    func imageOverlay<O: View>(@ViewBuilder _ imageOverlay: @escaping (PosterButtonType<Item>) -> O)
    -> PosterButton<Item, Content, O, ContextMenu> {
        .init(
            state: state,
            type: type,
            itemScale: itemScale,
            horizontalAlignment: horizontalAlignment,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            onSelect: onSelect,
            singleImage: singleImage
        )
    }

    func contextMenu<M: View>(@ViewBuilder _ contextMenu: @escaping (PosterButtonType<Item>) -> M)
    -> PosterButton<Item, Content, ImageOverlay, M> {
        .init(
            state: state,
            type: type,
            itemScale: itemScale,
            horizontalAlignment: horizontalAlignment,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            onSelect: onSelect,
            singleImage: singleImage
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}

// MARK: default content view

struct PosterButtonDefaultContentView<Item: Poster>: View {

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
                    Text(item.displayName)
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
