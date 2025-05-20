//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension PlaylistItemView {

    struct ContentView: View {

        // MARK: - Environment

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        // MARK: - Properties

        private let columns = [GridItem(.flexible())]

        // MARK: - View-Models

        @ObservedObject
        var viewModel: PlaylistItemViewModel

        // MARK: - Body

        var body: some View {
            if viewModel.playlistItems.isEmpty {
                Text(L10n.none)
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.playlistItems, id: \.id) { item in
                        ItemView.PlaylistItemRow(item: item) {
                            router.route(to: \.item, item)
                        }
                        // TODO: Add when Playlist Editing exists
                        /* .contextMenu {

                         } */
                    }
                }
            }
        }
    }
}
