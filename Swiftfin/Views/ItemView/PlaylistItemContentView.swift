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

    struct PagingItemContentView: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: PlaylistItemViewModel

        var body: some View {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 500))], spacing: 20) {
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
            .onFirstAppear {
                viewModel.send(.refresh)
            }
        }
    }
}
