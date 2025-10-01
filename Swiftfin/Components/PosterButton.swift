//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct PosterButton<Item: Poster, Label: View>: View {

    @ForTypeInEnvironment<Item, (Any) -> PosterStyleEnvironment>(\.posterStyleRegistry)
    private var posterStyleRegistry

    @Namespace
    private var namespace

    @State
    private var posterSize: CGSize = .zero

    private let item: Item
    private let type: PosterDisplayType
    private let label: Label
    private let action: (Namespace.ID) -> Void

    private var posterStyle: PosterStyleEnvironment {
        posterStyleRegistry?(item) ?? .default
    }

    init(
        item: Item,
        type: PosterDisplayType,
        action: @escaping (Namespace.ID) -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.item = item
        self.type = type
        self.action = action
        self.label = label()
    }

    @ViewBuilder
    private func posterView(overlay: some View = EmptyView()) -> some View {
        VStack(alignment: .leading) {
            PosterImage(
                item: item,
                type: posterStyle.displayType
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay { overlay }
            .contentShape(.contextMenuPreview, Rectangle())
            .posterCornerRadius(posterStyle.displayType)
            .backport
            .matchedTransitionSource(id: "item", in: namespace)
            .posterShadow()

            Group {
                if Label.self != EmptyView.self {
                    label
                } else {
                    posterStyle.label
                }
            }
            .allowsHitTesting(false)
        }
    }

    var body: some View {
        Button {
            action(namespace)
        } label: {
            posterView(overlay: posterStyle.overlay)
                .trackingSize($posterSize)
        }
        .foregroundStyle(.primary, .secondary)
        .buttonStyle(.plain)
        .matchedContextMenu(for: item) {
            let frameScale = 1.3

            posterView()
                .frame(
                    width: posterSize.width * frameScale,
                    height: posterSize.height * frameScale
                )
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(uiColor: UIColor.secondarySystemGroupedBackground))
                }
        }
    }
}

extension PosterButton where Label == EmptyView {

    init(
        item: Item,
        type: PosterDisplayType,
        action: @escaping (Namespace.ID) -> Void
    ) {
        self.init(
            item: item,
            type: type,
            action: action
        ) {
            EmptyView()
        }
    }
}

struct TitleSubtitleContentView: View {

    let title: String?
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.regular)
                    .foregroundStyle(.primary)
                    .lineLimit(1, reservesSpace: true)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1, reservesSpace: true)
            }
        }
    }
}
