//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterButton<Item: Poster>: View {

    @Environment(\.viewContext)
    private var viewContext

    @Namespace
    private var namespace

    @State
    private var posterSize: CGSize = .zero

    let item: Item
    let displayType: PosterDisplayType
    let action: (Namespace.ID) -> Void

    @ViewBuilder
    private var contextMenuPreview: some View {
        // TODO: determine if want to be used or just increase size
        let frameScale = 1.3

        buttonLabel()
            .frame(
                width: posterSize.width * frameScale,
                height: posterSize.height * frameScale
            )
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondarySystemFill)
            }
    }

    @ViewBuilder
    private func posterImage(overlay: some View) -> some View {
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
        .posterContextMenu(for: item) {
            contextMenuPreview
                .withViewContext(viewContext)
        }
    }
}
