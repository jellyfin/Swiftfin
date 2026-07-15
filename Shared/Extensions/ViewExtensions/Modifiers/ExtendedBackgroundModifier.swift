//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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

    func mask(
        alignment: Alignment = .center,
        extendedBy insets: EdgeInsets,
        @ViewBuilder mask: () -> some View
    ) -> some View {
        modifier(
            ExtendedMaskModifier(
                alignment: alignment,
                insets: insets,
                mask: mask
            )
        )
    }

    func overlay(
        alignment: Alignment = .center,
        extendedBy insets: EdgeInsets,
        @ViewBuilder overlay: () -> some View
    ) -> some View {
        modifier(
            ExtendedOverlayModifier(
                alignment: alignment,
                insets: insets,
                overlay: overlay
            )
        )
    }
}

struct ExtendedBackgroundModifier<Background: View>: ViewModifier {

    @State
    private var contentSize: CGSize = .zero

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
            .trackingSize($contentSize)
            .background(alignment: alignment) {
                background
                    .frame(
                        width: contentSize.width + insets.leading + insets.trailing,
                        height: contentSize.height + insets.top + insets.bottom,
                        alignment: alignment
                    )
            }
    }
}

struct ExtendedMaskModifier<Mask: View>: ViewModifier {

    @State
    private var contentSize: CGSize = .zero

    private let alignment: Alignment
    private let insets: EdgeInsets
    private let mask: Mask

    init(
        alignment: Alignment,
        insets: EdgeInsets,
        @ViewBuilder mask: () -> Mask
    ) {
        self.alignment = alignment
        self.insets = insets
        self.mask = mask()
    }

    func body(content: Content) -> some View {
        content
            .trackingSize($contentSize)
            .mask(alignment: alignment) {
                mask
                    .frame(
                        width: contentSize.width + insets.leading + insets.trailing,
                        height: contentSize.height + insets.top + insets.bottom,
                        alignment: alignment
                    )
            }
    }
}

struct ExtendedOverlayModifier<Overlay: View>: ViewModifier {

    @State
    private var contentSize: CGSize = .zero

    private let alignment: Alignment
    private let insets: EdgeInsets
    private let overlay: Overlay

    init(
        alignment: Alignment,
        insets: EdgeInsets,
        @ViewBuilder overlay: () -> Overlay
    ) {
        self.alignment = alignment
        self.insets = insets
        self.overlay = overlay()
    }

    func body(content: Content) -> some View {
        content
            .trackingSize($contentSize)
            .overlay(alignment: alignment) {
                overlay
                    .frame(
                        width: contentSize.width + insets.leading + insets.trailing,
                        height: contentSize.height + insets.top + insets.bottom,
                        alignment: alignment
                    )
            }
    }
}
