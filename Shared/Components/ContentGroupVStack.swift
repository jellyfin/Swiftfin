//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ContentGroupVStack: View {

    private let groups: [any ContentGroup]
    private let focusedGroupID: FocusState<String?>.Binding?

    init(
        groups: [any ContentGroup],
        focusedGroupID: FocusState<String?>.Binding? = nil
    ) {
        self.groups = groups
        self.focusedGroupID = focusedGroupID
    }

    private var spacing: CGFloat {
        #if os(tvOS)
        60
        #else
        20
        #endif
    }

    @ViewBuilder
    private func makeGroupBody(_ group: some ContentGroup) -> some View {
        group.body(with: group.viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(groups, id: \.id) { group in
                makeGroupBody(group)
                    .eraseToAnyView()
                    .ifLet(focusedGroupID) { view, binding in
                        view
                            .focused(binding, equals: group.id)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
