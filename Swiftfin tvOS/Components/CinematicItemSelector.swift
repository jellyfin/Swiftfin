//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CinematicItemSelector<Item: Poster, TopContent: View>: View {

    @Environment(\.frameForParentView)
    private var frameForParentView

    @FocusState
    private var isSectionFocused

    @FocusedValue(\.focusedPoster)
    private var focusedPoster

    @State
    private var backgroundItem: AnyPoster?

    private let action: (Item) -> Void
    private let items: [Item]
    private let topContent: (Item) -> TopContent

    init(
        items: [Item],
        action: @escaping (Item) -> Void,
        @ViewBuilder topContent: @escaping (Item) -> TopContent
    ) {
        self.items = items
        self.action = action
        self.topContent = topContent
    }

    private var parentFrame: CGRect {
        frameForParentView[.scrollView, default: .zero].frame
    }

    private var resolvedHeight: CGFloat {
        max(parentFrame.height - CinematicItemSelectorLayout.backgroundHeightOffset, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            if let focusedPoster, let focusedItem = focusedPoster._poster as? Item {
                topContent(focusedItem)
                    .id(focusedItem.hashValue)
                    .transition(.opacity)
            }

            // TODO: fix intrinsic content sizing without frame
            PosterHStack(
                elements: items,
                displayType: .landscape,
                size: .medium
            ) { item, _ in
                action(item)
            }
            .frame(height: CinematicItemSelectorLayout.posterRowHeight)
        }
        .frame(height: resolvedHeight, alignment: .bottomLeading)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            let selectedBackgroundItem = backgroundItem ?? items.first.map { AnyPoster($0) }

            FadeContentTransitionView(
                item: selectedBackgroundItem,
                debounce: 0.5
            ) { item in
                ImageView(item?.landscapeImageSources(environment: .default) ?? [])
                    .failure {
                        EmptyView()
                    }
                    .aspectRatio(contentMode: .fill)
            }
            .overlay {
                Color.black
                    .maskLinearGradient {
                        (location: 0.5, opacity: 0)
                        (location: 0.6, opacity: 0.4)
                        (location: 1, opacity: 1)
                    }
            }
            .frame(height: parentFrame.height)
            .maskLinearGradient {
                (location: 0.9, opacity: 1)
                (location: 1, opacity: 0)
            }
        }
        .onChange(of: focusedPoster) {
            guard let focusedPoster, isSectionFocused else { return }
            backgroundItem = focusedPoster
        }
        .focusSection()
        .focused($isSectionFocused)
        .debugBackground()
    }
}

private enum CinematicItemSelectorLayout {

    static let backgroundHeightOffset: CGFloat = 75
    static let posterRowHeight: CGFloat = 400
}

extension CinematicItemSelector where TopContent == EmptyView {

    init(
        items: [Item],
        action: @escaping (Item) -> Void = { _ in }
    ) {
        self.init(
            items: items,
            action: action
        ) { _ in
            EmptyView()
        }
    }
}
