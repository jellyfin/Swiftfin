//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: possibly consolidate with ChevronButton

/// A row for list leading and primary content, typically used
/// outside of a `List` or `Form`.
struct ListRow<Leading: View, Content: View>: View {

    @Environment(\.isFocused)
    private var isFocused

    @ViewContextContains(.isListRowSeparatorVisible)
    private var isListRowSeparatorVisible

    @State
    private var contentSize: CGSize = .zero

    private let action: () -> Void
    private let content: Content
    private var insets: EdgeInsets
    private var legacyIsSeparatorVisible: Bool
    private let leading: Leading

    private init(
        leading: Leading,
        content: Content,
        action: @escaping () -> Void,
        insets: EdgeInsets,
        isSeparatorVisible: Bool
    ) {
        self.leading = leading
        self.content = content
        self.action = action
        self.insets = insets
        self.legacyIsSeparatorVisible = isSeparatorVisible
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            Button(action: action) {
                HStack(alignment: .center, spacing: EdgeInsets.edgePadding) {

                    leading

                    content
                        .frame(maxHeight: .infinity)
                        .trackingSize($contentSize)
                }
                .padding(insets)
            }
            .foregroundStyle(.primary, .secondary)
            .contentShape(.contextMenuPreview, Rectangle())

            if legacyIsSeparatorVisible && isListRowSeparatorVisible && !isFocused {
                Color.secondarySystemFill
                    .frame(width: contentSize.width, height: 1)
                    .padding(.trailing, insets.trailing)
            }
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
            insets: insets,
            leading: leading,
            content: content,
            action: {}
        )
    }

    init(
        insets: EdgeInsets = .zero,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder content: @escaping () -> Content,
        action: @escaping () -> Void
    ) {
        self.init(
            leading: leading(),
            content: content(),
            action: action,
            insets: insets,
            isSeparatorVisible: true
        )
    }

    @available(*, deprecated, message: "Use viewContext.isListRowSeparatorVisible instead")
    func isSeparatorVisible(_ isVisible: Bool) -> Self {
        copy(modifying: \.legacyIsSeparatorVisible, with: isVisible)
    }
}
