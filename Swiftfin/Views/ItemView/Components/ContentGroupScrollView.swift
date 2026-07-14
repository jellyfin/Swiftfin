//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ContentGroupScrollView: View {

        let groups: [any ContentGroup]

        var body: some View {
            ScrollView {
                ContentGroupVStack(groups: groups)
                    .edgePadding(.bottom)
            }
            .ignoresSafeArea(edges: .horizontal)
            .scrollIndicators(.hidden)
        }
    }
}
