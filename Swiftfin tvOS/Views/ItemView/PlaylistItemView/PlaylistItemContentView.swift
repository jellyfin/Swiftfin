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

        var body: some View {
            VStack(spacing: 0) {

                ItemView.CinematicHeaderView(viewModel: viewModel)
                    .frame(height: UIScreen.main.bounds.height - 150)
                    .padding(.bottom, 50)

                if viewModel.playlistItems.isNotEmpty {

                    ForEach(viewModel.playlistItems.keys, id: \.self) { itemType in
                        if let sectionItems = viewModel.playlistItems[itemType], sectionItems.isNotEmpty {
                            PosterHStack(
                                // TODO: Use DisplayTitle or PluralDisplayTitle
                                title: itemType.rawValue,
                                type: .portrait,
                                items: sectionItems
                            )
                            .onSelect { item in
                                router.route(to: \.item, item)
                            }
                            /* TODO: Enable when Playlist Editing is Available
                             .contextMenu { _ in
                                 Button(role: .destructive) {
                                     // editorViewModel.send(removeFromPlaylist)
                                 } label: {
                                     Label("Remove from playlist", systemImage: "text.badge.minus")
                                 }
                             }*/
                        }
                    }
                }

                // MARK: About

                ItemView.AboutView(viewModel: viewModel)
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
