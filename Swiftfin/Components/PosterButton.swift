//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterButton<Item: Poster, Content: View, ImageOverlay: View, ContextMenu: View>: View {

    private var state: PosterButtonState<Item>
    private var type: PosterType
    private var itemScale: CGFloat
    private var horizontalAlignment: HorizontalAlignment
    private var content: () -> Content
    private var imageOverlay: () -> ImageOverlay
    private var contextMenu: () -> ContextMenu
    private var onSelect: () -> Void
    private var singleImage: Bool

    private var itemWidth: CGFloat {
        type.width * itemScale
    }

    @ViewBuilder
    private var loadingPoster: some View {
        VStack(alignment: horizontalAlignment) {
            Color.secondarySystemFill
                .posterStyle(type: type, width: itemWidth)

            PosterButtonDefaultContentView(state: PosterButtonState<Item>.loading)
        }
        .redacted(reason: .placeholder)
    }

    @ViewBuilder
    private var noResultsPoster: some View {
        VStack(alignment: horizontalAlignment) {
            Color.red
                .posterStyle(type: type, width: itemWidth)

            PosterButtonDefaultContentView(state: PosterButtonState<Item>.noResult)
        }
    }

    @ViewBuilder
    private func poster(from item: Item) -> some View {
        VStack(alignment: horizontalAlignment) {
            Button {
                onSelect()
            } label: {
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
                .overlay {
                    imageOverlay()
                        .posterStyle(type: type, width: itemWidth)
                }
            }
            .contextMenu(menuItems: {
                contextMenu()
            })
            .posterStyle(type: type, width: itemWidth)
            .posterShadow()

            content()
        }
    }

    var body: some View {
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
        .frame(width: itemWidth)
    }
}

extension PosterButton where Content == PosterButtonDefaultContentView<Item>,
    ImageOverlay == EmptyView,
    ContextMenu == EmptyView
{

    init(state: PosterButtonState<Item>, type: PosterType, singleImage: Bool = false) {
        self.init(
            state: state,
            type: type,
            itemScale: 1,
            horizontalAlignment: .leading,
            content: { PosterButtonDefaultContentView(state: state) },
            imageOverlay: { EmptyView() },
            contextMenu: { EmptyView() },
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

    @ViewBuilder
    func content<C: View>(@ViewBuilder _ content: @escaping () -> C) -> PosterButton<Item, C, ImageOverlay, ContextMenu> {
        PosterButton<Item, C, ImageOverlay, ContextMenu>(
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

    @ViewBuilder
    func imageOverlay<O: View>(@ViewBuilder _ imageOverlay: @escaping () -> O) -> PosterButton<Item, Content, O, ContextMenu> {
        PosterButton<Item, Content, O, ContextMenu>(
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

    @ViewBuilder
    func contextMenu<M: View>(@ViewBuilder _ contextMenu: @escaping () -> M) -> PosterButton<Item, Content, ImageOverlay, M> {
        PosterButton<Item, Content, ImageOverlay, M>(
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

    let state: PosterButtonState<Item>

    @ViewBuilder
    private var loadingContent: some View {
        String(repeating: "a", count: Int.random(in: 5 ..< 8)).text
            .font(.footnote)
            .fontWeight(.regular)
            .foregroundColor(.primary)
            .redacted(reason: .placeholder)
    }

    @ViewBuilder
    private var noResultsContent: some View {
        L10n.noResults.text
            .font(.footnote)
            .fontWeight(.regular)
            .foregroundColor(.primary)
            .lineLimit(2)
    }

    @ViewBuilder
    private func itemContent(from item: Item) -> some View {
        if item.showTitle {
            Text(item.displayName)
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

    var body: some View {
        VStack(alignment: .leading) {
            switch state {
            case .loading:
                loadingContent
            case .noResult:
                noResultsContent
            case let .item(item):
                itemContent(from: item)
            }
        }
    }
}
