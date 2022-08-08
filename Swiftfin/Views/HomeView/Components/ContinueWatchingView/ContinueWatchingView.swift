//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ContinueWatchingView: View {

    @EnvironmentObject
    private var homeRouter: HomeCoordinator.Router
    @ObservedObject
    var viewModel: HomeViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 20) {
                ForEach(viewModel.resumeItems, id: \.id) { item in
                    ContinueWatchingLandscapeButton(item: item)
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.removeItemFromResume(item)
                            } label: {
                                Label(L10n.removeFromResume, systemImage: "minus.circle")
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}
