//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EpisodeItemView: View {

    @EnvironmentObject
    private var itemRouter: ItemCoordinator.Router
    @State
    private var scrollViewOffset: CGFloat = 0
    @ObservedObject
    var viewModel: EpisodeItemViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            ContentView(viewModel: viewModel)
        }
        .scrollViewOffset($scrollViewOffset)
        .navBarOffset(
            $scrollViewOffset,
            start: 0,
            end: 10
        )
    }
}
