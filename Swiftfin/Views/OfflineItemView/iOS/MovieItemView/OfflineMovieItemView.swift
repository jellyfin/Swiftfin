//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct OfflineMovieItemView: View {

    @Default(.Customization.itemViewType)
    private var itemViewType

    @ObservedObject
    var offlineViewModel: OfflineViewModel

    @ObservedObject
    var viewModel: OfflineMovieItemViewModel

    var body: some View {
        switch itemViewType {
        case .compactPoster:
            OfflineItemView.CompactPosterScrollView(viewModel: viewModel, offlineViewModel: offlineViewModel) {
                ContentView(viewModel: viewModel)
            }
        case .compactLogo:
            OfflineItemView.CompactLogoScrollView(viewModel: viewModel, offlineViewModel: offlineViewModel) {
                ContentView(viewModel: viewModel)
            }
        case .cinematic:
            OfflineItemView.CinematicScrollView(viewModel: viewModel, offlineViewModel: offlineViewModel) {
                ContentView(viewModel: viewModel)
            }
        }
    }
}
