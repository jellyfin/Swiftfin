//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

@MainActor
struct EpisodeQueueView: View {

    @Environment(MediaSession.self)
    private var mediaSession

    @StateObject
    private var viewModel: PagingLibraryViewModel<EpisodeLibrary>

    init(season: BaseItemDto) {
        _viewModel = StateObject(wrappedValue: PagingLibraryViewModel(library: EpisodeLibrary(season: season)))
    }

    private func select(_ entry: ItemEntry) {
        mediaSession.playNewItem(intent: PlaybackIntent(item: entry.snapshot, requestedBitrate: mediaSession.playbackBitrate))
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                QueueItemsView(
                    items: viewModel.elements,
                    currentEntryID: mediaSession.item.id.map { ItemEntry.ID(itemID: $0, occurrence: nil) },
                    action: select
                )

            case .initial, .refreshing:
                EmptyView()

            case .error:
                QueueErrorView { viewModel.refresh() }
            }
        }
        .onFirstAppear { viewModel.refresh() }
    }
}
