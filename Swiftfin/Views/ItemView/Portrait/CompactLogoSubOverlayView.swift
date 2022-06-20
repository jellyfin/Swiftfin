//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CompactLogoSubOverlayView: View {
    
    @EnvironmentObject
    var itemRouter: ItemCoordinator.Router
    @ObservedObject
    private var viewModel: ItemViewModel
    
    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            ItemView.DotHStackView()
                .environmentObject(viewModel)
            
            ItemView.AttributesHStackView()
                .environmentObject(viewModel)
            
            ItemView.PlayButton(viewModel: viewModel)
                .frame(maxWidth: 300)
                .frame(height: 50)
            
            ItemView.ItemActionHStackView()
                .environmentObject(viewModel)
                .frame(maxWidth: 300)
        }
        .padding(.horizontal)
    }
}
