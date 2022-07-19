//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct MovieItemView: View {

    @ObservedObject
    var viewModel: MovieItemViewModel
    @Default(.itemViewType)
    private var itemViewType

    var body: some View {
        switch itemViewType {
        case .compactPoster:
            ItemView.CompactPosterScrollView(viewModel: viewModel) {
                ContentView(viewModel: viewModel)
            }
        case .compactLogo:
            ItemView.CompactLogoScrollView(viewModel: viewModel) {
                ContentView(viewModel: viewModel)
            }
        case .cinematic:
            ItemView.CinematicScrollView(viewModel: viewModel) {
                ContentView(viewModel: viewModel)
            }
        }
    }
}
