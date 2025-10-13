//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: come up with better name along with `ListRowButton`

// Meant to be used when making a custom list without `List` or `Form`
struct ListRow<Leading: View, Content: View>: View {

    @State
    private var contentSize: CGSize = .zero

    private var action: () -> Void
    private let content: Content
    private var insets: EdgeInsets
    private let leading: Leading

    init(
        insets: EdgeInsets = .zero,
        action: @escaping () -> Void,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.action = action
        self.content = content()
        self.insets = insets
        self.leading = leading()
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: EdgeInsets.edgePadding) {

                leading

                content
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .leading
                    )
                    .trackingSize($contentSize)
            }
            .padding(insets)
        }
        .foregroundStyle(.primary, .secondary)
        .contentShape(.contextMenuPreview, Rectangle())
//        .listRowSeparator(.hidden)
        .overlay(alignment: .bottomTrailing) {
            Color.secondarySystemFill
                .frame(
                    width: contentSize.width + insets.trailing,
                    height: 1
                )
        }
    }
}
