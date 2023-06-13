//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemOverviewView: View {

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    let item: BaseItemDto

    var body: some View {
        ScrollView(showsIndicators: false) {
            ItemView.OverviewView(item: item)
                .padding()
        }
        .navigationTitle(L10n.overview)
        .navigationBarTitleDisplayMode(.inline)
        .navigationCloseButton {
            router.dismissCoordinator()
        }
    }
}
