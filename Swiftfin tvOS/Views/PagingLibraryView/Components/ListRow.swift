//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: come up with better name along with `ListRowButton`

// Meant to be used when making a custom list without `List` or `Form`
struct ListRow<Leading: View, Content: View>: View {

    @State
    private var contentSize: CGSize = .zero

    private let leading: Leading
    private let content: Content
    private var action: () -> Void
    private var insets: EdgeInsets
    private var isSeparatorVisible: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            Button {
                action()
            } label: {
                HStack(alignment: .center, spacing: EdgeInsets.edgePadding) {

                    leading

                    content
                        .frame(maxHeight: .infinity)
                        .trackingSize($contentSize)
                }
                .padding(.top, insets.top)
                .padding(.bottom, insets.bottom)
                .padding(.leading, insets.leading)
                .padding(.trailing, insets.trailing)
            }
            .foregroundStyle(.primary, .secondary)
            .buttonStyle(.plain)

            Color.secondarySystemFill
                .frame(width: contentSize.width, height: 1)
                .padding(.trailing, insets.trailing)
                .isVisible(isSeparatorVisible)
        }
    }
}

extension ListRow {

    init(
        insets: EdgeInsets = .zero,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            leading: leading(),
            content: content(),
            action: {},
            insets: insets,
            isSeparatorVisible: true
        )
    }

    func isSeparatorVisible(_ isVisible: Bool) -> Self {
        copy(modifying: \.isSeparatorVisible, with: isVisible)
    }

    func onSelect(perform action: @escaping () -> Void) -> Self {
        copy(modifying: \.action, with: action)
    }
}
