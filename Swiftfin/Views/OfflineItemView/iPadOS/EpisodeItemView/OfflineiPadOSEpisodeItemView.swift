//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct OfflineiPadOSEpisodeItemView: View {
    @ObservedObject
    var offlineViewModel: OfflineViewModel
    @ObservedObject
    var viewModel: OfflineEpisodeItemViewModel

    var body: some View {
        OfflineItemView.iPadOSCinematicScrollView(viewModel: viewModel) {
            ContentView(viewModel: viewModel)
        }
    }
}
