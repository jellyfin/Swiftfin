//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct SupplementPosterButton<Item: Poster, Label: View>: View {

    @Default(.accentColor)
    private var accentColor

    @Environment(\.isSelected)
    private var isSelected

    private let action: () -> Void
    private let item: Item
    private let label: Label

    init(
        item: Item,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.item = item
        self.action = action
        self.label = label()
    }

    @ViewBuilder
    private func overlay(for posterItem: Item) -> some View {
        if isSelected {
            ContainerRelativeShape()
                .stroke(accentColor, lineWidth: UIDevice.isTV ? 12 : 8)
                .clipped()
        }

        PosterButton.DefaultOverlay(item: posterItem)
    }

    var body: some View {
        #if os(tvOS)
        PosterButton(
            item: item,
            type: .landscape,
            action: action
        ) {
            label
        }
        .posterOverlay(for: Item.self) { posterItem in
            overlay(for: posterItem)
        }
        #else
        PosterButton(
            item: item,
            type: .landscape,
            action: { _ in action() }
        ) {
            label
        }
        .posterOverlay(for: Item.self) { posterItem in
            overlay(for: posterItem)
        }
        #endif
    }
}
