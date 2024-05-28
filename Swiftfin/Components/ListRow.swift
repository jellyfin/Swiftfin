//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: come up with better name along with `ListRowButton`

// Meant to be used when making a custom list without `List` or `Form`
struct ListRow<Leading: View, Content: View>: View {

    private let leading: () -> Leading
    private let content: () -> Content
    private var action: () -> Void
    private var insets: CGFloat

    var body: some View {
        Button {
            action()
        } label: {
            HStack(alignment: .center, spacing: EdgeInsets.edgePadding) {

                leading()

                ZStack(alignment: .bottom) {
                    content()
                        .frame(maxHeight: .infinity)

                    Color.secondarySystemFill
                        .frame(height: 1, alignment: .bottom)
                }
            }
            .padding()
        }
        .foregroundStyle(.primary, .secondary)
    }
}

extension ListRow {

    init(
        insets: CGFloat = 0,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            leading: leading,
            content: content,
            action: {}
        )
    }

    func onSelect(perform action: @escaping () -> Void) -> Self {
        copy(modifying: \.action, with: action)
    }
}
