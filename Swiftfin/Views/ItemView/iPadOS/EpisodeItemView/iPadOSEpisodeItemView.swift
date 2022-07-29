//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct iPadOSEpisodeItemView: View {

    @EnvironmentObject
    private var itemRouter: ItemCoordinator.Router
    @ObservedObject
    var viewModel: EpisodeItemViewModel

    var body: some View {
        Text("N/A")
//        NavBarOffsetScrollView(headerHeight: 10) {
//            ContentView(viewModel: viewModel)
//        }
    }
}
