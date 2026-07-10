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
            insets: .init(vertical: 5, horizontal: 10),
            spacing: 2,
            tint: isHighlighted ? .accentColor : nil,
            isTitleVisible: !isIconOnly,
            isIconTrailing: !isIconOnly
        )
        .makeBody(configuration: configuration)
        .font(.footnote)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
    }
}
