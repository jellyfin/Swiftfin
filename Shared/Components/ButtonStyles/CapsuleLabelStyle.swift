//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CapsuleLabelStyle: LabelStyle {

    private let insets: EdgeInsets?
    private let spacing: CGFloat
    private let tint: Color?
    private let isTitleVisible: Bool
    private let isIconTrailing: Bool

    static var defaultInsets: EdgeInsets {
        #if os(tvOS)
        .init(vertical: 10, horizontal: 20)
        #else
        .init(vertical: 5, horizontal: 10)
        #endif
    }

    init(
        insets: EdgeInsets? = nil,
        spacing: CGFloat = 4,
        tint: Color? = nil,
        isTitleVisible: Bool = true,
        isIconTrailing: Bool = false
    ) {
        self.insets = insets
        self.spacing = spacing
        self.tint = tint
        self.isTitleVisible = isTitleVisible
        self.isIconTrailing = isIconTrailing
    }

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        let content = HStack(spacing: spacing) {
            if !isIconTrailing {
                configuration.icon
            }

            if isTitleVisible {
                configuration.title
            }

            if isIconTrailing {
                configuration.icon
            }
        }
        .padding(insets ?? Self.defaultInsets)

        if let tint {
            content
                .backport
                .glassEffect(
                    .regular.selection(
                        tint: tint,
                        foregroundColor: tint.overlayColor
                    ),
                    in: .capsule
                )
        } else {
            content
                .backport
                .glassEffect(in: .capsule)
        }
    }
}
