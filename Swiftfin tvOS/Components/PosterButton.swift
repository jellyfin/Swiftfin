//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

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
    private var onFocus: () -> Void
    private var singleImage: Bool

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
            .focused($isFocused)

            content()
                .eraseToAnyView()
                .zIndex(-1)
        }
        .frame(width: itemWidth)
        .onChange(of: isFocused) { newValue in
            guard newValue else { return }
            onFocus()
        }
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
            imageOverlay: { EmptyView() },
            contextMenu: { EmptyView() },
            onSelect: {},
            onFocus: {},
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
    func content(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.content, with: content)
//        PosterButton<Item, C, ImageOverlay, ContextMenu>(
//            item: item,
//            type: type,
//            itemScale: itemScale,
//            horizontalAlignment: horizontalAlignment,
//            content: content,
//            imageOverlay: imageOverlay,
//            contextMenu: contextMenu,
//            onSelect: onSelect,
//            onFocus: onFocus,
//            singleImage: singleImage
//        )
    }

    @ViewBuilder
    func imageOverlay(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.imageOverlay, with: content)
//        PosterButton<Item, Content, O, ContextMenu>(
//            item: item,
//            type: type,
//            itemScale: itemScale,
//            horizontalAlignment: horizontalAlignment,
//            content: content,
//            imageOverlay: imageOverlay,
//            contextMenu: contextMenu,
//            onSelect: onSelect,
//            onFocus: onFocus,
//            singleImage: singleImage
//        )
    }

    @ViewBuilder
    func contextMenu(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.contextMenu, with: content)
//        PosterButton<Item, Content, ImageOverlay, M>(
//            item: item,
//            type: type,
//            itemScale: itemScale,
//            horizontalAlignment: horizontalAlignment,
//            content: content,
//            imageOverlay: imageOverlay,
//            contextMenu: contextMenu,
//            onSelect: onSelect,
//            onFocus: onFocus,
//            singleImage: singleImage
//        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }

    func onFocus(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onFocus, with: action)
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
}
