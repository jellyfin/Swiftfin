//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EpisodeItemView: View {

    @EnvironmentObject
    private var router: ItemCoordinator.Router

    @ObservedObject
    var viewModel: EpisodeItemViewModel

    @State
    private var scrollViewOffset: CGFloat = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            ContentView(viewModel: viewModel)
        }
        .scrollViewOffset($scrollViewOffset)
        .navigationBarOffset(
            $scrollViewOffset,
            start: 0,
            end: 30
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}
