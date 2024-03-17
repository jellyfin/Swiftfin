//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct iPadOSEpisodeItemView: View {

    @EnvironmentObject
    private var router: ItemCoordinator.Router

    @StateObject
    private var viewModel: EpisodeItemViewModel

    init(item: BaseItemDto) {
        self._viewModel = StateObject(wrappedValue: EpisodeItemViewModel(item: item))
    }

    var body: some View {
        ItemView.iPadOSCinematicScrollView(viewModel: viewModel) {
            ContentView(viewModel: viewModel)
        }
    }
}
