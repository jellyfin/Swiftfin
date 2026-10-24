//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
struct QueueItemsView<Items: RandomAccessCollection>: View
    where Items.Element == ItemEntry, Items.Index == Int
{

    @Environment(VideoPlayer.ViewState.self)
    private var viewState

    let items: Items
    let currentEntryID: ItemEntry.ID?
    var displayType: PosterDisplayType = .landscape
    let action: (ItemEntry) -> Void

    var body: some View {
        if !items.isEmpty {
            VideoPlayer.PosterCollectionView(
                data: items,
                currentElementID: currentEntryID,
                isCompact: viewState.isCompact,
                displayType: displayType,
                action: action
            ) { item in
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    DotHStack {
                        if let subtitle = item.subtitle {
                            Text(subtitle)
                        }

                        if let runtime = item.snapshot.runTimeLabel {
                            Text(runtime)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}
