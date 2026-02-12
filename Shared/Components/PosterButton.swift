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

struct PosterButton<Item: Poster, Label: View>: View {

    @Environment(\.viewContext)
    private var viewContext

    @Namespace
    private var namespace

    @State
    private var posterFrame: CGRect = .zero

    private let item: Item
    private let type: PosterDisplayType
    private let size: PosterDisplayType.Size
    private let label: Label
    private let action: (Namespace.ID) -> Void

    init(
        item: Item,
        type: PosterDisplayType,
        size: PosterDisplayType.Size = .small,
        action: @escaping (Namespace.ID) -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.item = item
        self.type = type
        self.size = size
        self.action = action
        self.label = label()
    }

    @ViewBuilder
    private func posterImage(overlay: some View = EmptyView()) -> some View {
        PosterImage(
            item: item,
            type: type,
            size: size
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay { overlay }
        .contentShape(.contextMenuPreview, Rectangle())
        .posterCornerRadius(type)
        .backport
        .matchedTransitionSource(id: "item", in: namespace)
        .posterShadow()
        .hoverEffect(.highlight)
    }

    @ViewBuilder
    private var resolvedLabel: some View {
        Group {
            if Label.self != EmptyView.self {
                label
            } else {
                item.posterLabel
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func buttonLabel(overlay: some View = EmptyView()) -> some View {
        VStack(alignment: .leading) {
            posterImage(overlay: overlay)

            resolvedLabel
        }
    }

    var body: some View {
        Button {
            action(namespace)
        } label: {
            // Layout required for tvOS focused offset label behavior
            #if os(tvOS)
            posterImage(overlay: item.posterOverlay(for: type))
            resolvedLabel
                .frame(maxWidth: .infinity, alignment: .leading)
            #else
            buttonLabel(overlay: item.posterOverlay(for: type))
                .trackingFrame($posterFrame)
            #endif
        }
        .foregroundStyle(.primary, .secondary)
        .accessibilityLabel(item.displayTitle)
        .buttonStyle(.borderless)
        .focusedValue(\.focusedPoster, .init(item))
        .matchedContextMenu(for: item) {
            let frameScale = 1.3

            buttonLabel()
                .withViewContext(viewContext)
                .frame(
                    width: posterFrame.width * frameScale,
                    height: posterFrame.height * frameScale
                )
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.complexSecondary)
                }
        }
    }
}

extension PosterButton where Label == EmptyView {

    init(
        item: Item,
        type: PosterDisplayType,
        size: PosterDisplayType.Size = .small,
        action: @escaping (Namespace.ID) -> Void
    ) {
        self.init(
            item: item,
            type: type,
            size: size,
            action: action
        ) {
            EmptyView()
        }
    }
}

// TODO: turn into a LabelStyle?
struct TitleSubtitleContentView<Content: View>: View {

    private let title: String
    private let content: Content

    init(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .fontWeight(.regular)
                .foregroundStyle(.primary)
                .lineLimit(1, reservesSpace: true)

            content
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .lineLimit(1, reservesSpace: true)
        }
        .font(.footnote)
    }
}

extension TitleSubtitleContentView where Content == Text {

    init(
        title: String,
        subtitle: String
    ) {
        self.title = title
        self.content = Text(subtitle)
    }
}
