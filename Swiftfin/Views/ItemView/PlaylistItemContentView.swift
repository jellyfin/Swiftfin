//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct PlaylistItemContentView: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: PlaylistItemViewModel

        var body: some View {
            SeparatorVStack(alignment: .leading) {
                RowDivider()
                    .padding(.vertical, 10)
            } content: {

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 500))], spacing: 10) {
                    ForEach(viewModel.playlistItems) { item in
                        ItemView.PlayableContentRow(item: item) {
                            router.route(to: .item(item: item))
                        }
                    }
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
