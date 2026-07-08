//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ContentGroupVStack: View {

    let groups: [any ContentGroup]

    @ViewBuilder
    private func makeGroupBody(_ group: some ContentGroup) -> some View {
        group.body(with: group.viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(groups, id: \.id) { group in
                makeGroupBody(group)
                    .eraseToAnyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
