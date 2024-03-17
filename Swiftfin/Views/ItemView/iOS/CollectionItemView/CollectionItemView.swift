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

struct CollectionItemView: View {

    @Default(.Customization.itemViewType)
    private var itemViewType

    @StateObject
    private var viewModel: CollectionItemViewModel

    init(item: BaseItemDto) {
        self._viewModel = StateObject(wrappedValue: CollectionItemViewModel(item: item))
    }

    var body: some View {
        WrappedView {
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
        .onFirstAppear {
            viewModel.send(.refresh)
        }
    }
}
