//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension PlaylistItemView {

    struct ContentView: View {

        @ObservedObject
        var viewModel: PlaylistItemViewModel

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        private let columns = [GridItem(.flexible()), GridItem(.flexible())]

        var body: some View {
            VStack(spacing: 0) {

                ItemView.CinematicHeaderView(viewModel: viewModel)
                    .frame(height: UIScreen.main.bounds.height - 150)
                    .padding(.bottom, 50)

                if viewModel.playlistItems.isEmpty {
                    Text(L10n.none)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(viewModel.playlistItems, id: \.id) { item in
                            ItemView.PlaylistItemRow(item: item) {
                                router.route(to: \.item, item)
                            }
                            .padding(.horizontal)
                            // TODO: Add when Playlist Editing exists
                            /* .contextMenu {

                             } */
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background {
                BlurView(style: .dark)
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.5),
                                    .init(color: .white.opacity(0.8), location: 0.7),
                                    .init(color: .white.opacity(0.8), location: 0.95),
                                    .init(color: .white, location: 1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: UIScreen.main.bounds.height - 150)

                            Color.white
                        }
                    }
            }
        }
    }
}
