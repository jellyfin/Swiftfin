//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct NavigationDrawerLabelStyle: LabelStyle {

    #if os(macOS)
    /// Mac control density, so the drawer reads as a compact toolbar strip
    /// instead of a row of touch-sized pills.
    private static let insets: EdgeInsets? = .init(vertical: 3, horizontal: 8)
    private static let font: Font = .caption
    private static let fontWeight: Font.Weight = .medium
    #else
    private static let insets: EdgeInsets? = nil
    private static let font: Font = .footnote
    private static let fontWeight: Font.Weight = .semibold
    #endif

    @Environment(\.isHighlighted)
    private var isHighlighted

    private let isIconOnly: Bool

    var iconOnly: NavigationDrawerLabelStyle {
        NavigationDrawerLabelStyle(isIconOnly: true)
    }

    init(isIconOnly: Bool = false) {
        self.isIconOnly = isIconOnly
    }

    func makeBody(configuration: Configuration) -> some View {
        CapsuleLabelStyle(
            insets: Self.insets,
            spacing: 2,
            tint: isHighlighted ? .accentColor : nil,
            isTitleVisible: !isIconOnly,
            isIconTrailing: !isIconOnly
        )
        .makeBody(configuration: configuration)
        .font(Self.font)
        .fontWeight(Self.fontWeight)
        .foregroundStyle(.primary)
    }
}
