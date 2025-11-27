//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import JellyfinAPI
import SwiftUI

enum MediaPlayerQueueItemViews {

    struct ItemPreview: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected: Bool

        let item: BaseItemDto

        var body: some View {
            ZStack {
                Rectangle()
                    .fill(.complexSecondary)

                ImageView(item.imageSource(.primary, maxWidth: 200))
                    .failure {
                        SystemImageContentView(systemName: item.systemImage)
                    }
            }
            .overlay {
                if isSelected {
                    ContainerRelativeShape()
                        .stroke(
                            accentColor,
                            lineWidth: 8
                        )
                        .clipped()
                }
            }
            .posterStyle(.landscape)
        }
    }

    struct ItemDescription: View {

        let item: BaseItemDto

        var body: some View {
            DotHStack {
                if item.type == .episode, let seasonEpisodeLabel = item.seasonEpisodeLabel {
                    Text(seasonEpisodeLabel)
                }

                if let runtime = item.runTimeLabel {
                    Text(runtime)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    struct ItemRow: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var manager: MediaPlayerManager

        let item: BaseItemDto
        let action: () -> Void

        private var isCurrentItem: Bool {
            manager.item.id == item.id
        }

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                ItemPreview(item: item)
                    .frame(width: 110)
                    .padding(.vertical, 8)
            } content: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    ItemDescription(item: item)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onSelect(perform: action)
            .isSelected(isCurrentItem)
        }
    }

    struct ItemButton: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var manager: MediaPlayerManager

        let item: BaseItemDto
        let action: () -> Void

        private var isCurrentItem: Bool {
            manager.item.id == item.id
        }

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 5) {
                    ItemPreview(item: item)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.displayTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                            .frame(height: 15)

                        ItemDescription(item: item)
                            .frame(height: 20, alignment: .top)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .foregroundStyle(.primary, .secondary)
            .isSelected(isCurrentItem)
        }
    }

    struct QueueHStack<Data: Collection>: View where Data.Element == BaseItemDto, Data.Index == Int {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @StateObject
        private var proxy = CollectionHStackProxy()

        let items: Data
        let action: (BaseItemDto) -> Void

        var body: some View {
            CollectionHStack(
                uniqueElements: items,
                id: \.unwrappedIDHashOrZero
            ) { item in
                ItemButton(item: item) {
                    action(item)
                }
                .frame(height: 150)
            }
            .scrollBehavior(.continuousLeadingEdge)
            .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
            .proxy(proxy)
            .onAppear {
                scrollToCurrentItem()
            }
            .onChange(of: manager.item.id) { _ in
                scrollToCurrentItem()
            }
            .onChange(of: items.count) { _ in
                scrollToCurrentItem()
            }
        }

        private func scrollToCurrentItem() {
            guard let currentItemID = manager.item.id else { return }
            guard let currentItem = items.first(where: { $0.id == currentItemID }) else { return }
            proxy.scrollTo(id: currentItem.unwrappedIDHashOrZero, animated: false)
        }
    }
}
