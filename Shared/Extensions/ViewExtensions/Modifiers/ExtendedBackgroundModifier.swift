//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension View {

    func background(
        alignment: Alignment = .center,
        extendedBy insets: EdgeInsets,
        @ViewBuilder background: () -> some View
    ) -> some View {
        modifier(
            ExtendedBackgroundModifier(
                alignment: alignment,
                insets: insets,
                background: background
            )
        )
    }
}

struct ExtendedBackgroundModifier<Background: View>: ViewModifier {

    @State
    private var contentFrame: CGRect = .zero

    private let alignment: Alignment
    private let background: Background
    private let insets: EdgeInsets

    init(
        alignment: Alignment,
        insets: EdgeInsets = .init(),
        @ViewBuilder background: () -> Background
    ) {
        self.alignment = alignment
        self.background = background()
        self.insets = insets
    }

    func body(content: Content) -> some View {
        content
            .trackingFrame($contentFrame)
            .background(alignment: alignment) {
                background
                    .frame(
                        width: contentFrame.width + insets.leading + insets.trailing,
                        height: contentFrame.height + insets.top + insets.bottom
                    )
            }
    }
}
