//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterButton<Item: Poster>: View {

    @Namespace
    private var namespace

    @State
    private var posterSize: CGSize = .zero

    private let action: (Namespace.ID) -> Void
    private let displayType: PosterDisplayType
    private let item: Item

    init(
        item: Item,
        type: PosterDisplayType,
        action: @escaping (Namespace.ID) -> Void
    ) {
        self.action = action
        self.displayType = type
        self.item = item
    }

    @ViewBuilder
    private func posterImage(overlay: some View) -> some View {
//        #if os(tvOS)
//        PosterImage(item: item, type: displayType)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .overlay { overlay }
//            .contentShape(.contextMenuPreview, Rectangle())
//            .posterStyle(displayType)
//            .posterShadow()
//            .hoverEffect(.highlight)
//        #else
//        PosterImage(item: item, type: displayType)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .overlay { overlay }
//            .contentShape(.contextMenuPreview, Rectangle())
//            .posterCornerRadius(displayType)
//            .backport
//            .matchedTransitionSource(id: "item", in: namespace)
//            .posterShadow()
//        #endif

        PosterImage(
            item: item,
            type: displayType
        )
        .overlay { overlay.posterStyle(displayType) }
        .contentShape(.contextMenuPreview, Rectangle())
        .backport
        .matchedTransitionSource(id: "item", in: namespace)
        .posterShadow()
        .hoverEffect(.highlight)
    }

    @ViewBuilder
    private func buttonLabel(overlay: some View = EmptyView()) -> some View {
        VStack(alignment: .leading) {
            posterImage(overlay: overlay)

            item.posterLabel
                .allowsHitTesting(false)
        }
    }

    var body: some View {
        Button {
            action(namespace)
        } label: {
            // Layout required for tvOS focused offset label behavior
            #if os(tvOS)
            posterImage(overlay: item.posterOverlay(for: displayType))

            item.posterLabel
                .frame(maxWidth: .infinity, alignment: .leading)
            #else
            buttonLabel(overlay: item.posterOverlay(for: displayType))
                .trackingSize($posterSize)
            #endif
        }
        .foregroundStyle(.primary, .secondary)
        .buttonStyle(.borderless)
        .buttonBorderShape(.roundedRectangle)
        .focusedValue(\.focusedPoster, AnyPoster(item))
//        .buttonStyle(.plain)
//        .matchedContextMenu(for: item) {
//            let frameScale = 1.3
//
//            posterView()
//                .frame(
//                    width: posterSize.width * frameScale,
//                    height: posterSize.height * frameScale
//                )
//                .padding(20)
//                .background {
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(Color(uiColor: UIColor.secondarySystemGroupedBackground))
//                }
//        }
//        #endif
    }
}
