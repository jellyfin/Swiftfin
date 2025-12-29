//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A view for usage in a plain `List` or a `CollectionVGrid`
struct ListRow<Leading: View, Content: View>: View {

    @State
    private var contentFrame: CGRect = .zero

    private let action: () -> Void
    private let content: Content
    private let insets: EdgeInsets
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
            HStack(spacing: EdgeInsets.edgePadding) {

                leading

                content
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .leading
                    )
                    .trackingFrame($contentFrame)
            }
            .padding(insets)
        }
        .foregroundStyle(.primary, .secondary)
        .contentShape(.contextMenuPreview, Rectangle())
        .listRowSeparator(.hidden)
        .overlay(alignment: .bottomTrailing) {
//            Color.secondarySystemFill
            Divider()
                .frame(
                    width: contentFrame.width + insets.trailing
//                    height: 1
                )
        }
    }
}
