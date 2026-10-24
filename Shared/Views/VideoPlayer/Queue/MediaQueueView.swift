//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
struct MediaQueueView: @MainActor VideoPlayerSupplement {

    @Environment(VideoPlayer.ViewState.self)
    private var viewState

    let queue: any MediaPlayerQueue
    var displayType: PosterDisplayType = .landscape

    var id: String {
        "Queue-\(ObjectIdentifier(queue))"
    }

    var displayTitle: String {
        L10n.queue
    }

    @ViewBuilder
    private var itemsView: some View {
        if queue.items.isNotEmpty {
            VideoPlayer.PosterCollectionView(
                data: queue.items,
                currentElementID: queue.currentEntryID,
                isCompact: viewState.isCompact,
                displayType: displayType,
                action: queue.select
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

    var body: some View {
        switch queue.state {
        case .content:
            itemsView

        case .initial, .loading:
            EmptyView()

        case .error:
            QueueErrorView(retry: queue.refresh)
        }
    }
}
