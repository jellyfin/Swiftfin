//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct PlaylistItemContentView: View {

        @ObservedObject
        var viewModel: PlaylistItemViewModel

        @Router
        private var router

        var body: some View {
            VStack(spacing: 0) {

                ItemView.CinematicHeaderView(viewModel: viewModel)
                    .frame(height: UIScreen.main.bounds.height - 150)
                    .padding(.bottom, 50)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                    ForEach(viewModel.contents.elements) { item in
                        ItemView.PlayableContentRow(item: item) {
                            router.route(to: .item(item: item))
                        }
                        .onFirstAppear {
                            if item == viewModel.contents.elements.last {
                                viewModel.contents.send(.getNextPage)
                            }
                        }
                    }
                }
                .padding(EdgeInsets.edgePadding)

                ItemView.AboutView(viewModel: viewModel)
            }
            .onFirstAppear {
                viewModel.send(.refresh)
            }
        }
    }
}
