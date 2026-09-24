//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension LabelStyle where Self == HorizontalLabelStyle {

    static var leadingIcon: Self {
        HorizontalLabelStyle(iconEdge: .leading)
    }

    static var trailingIcon: Self {
        HorizontalLabelStyle(iconEdge: .trailing)
    }
}

struct HorizontalLabelStyle: LabelStyle {

    @Environment(\.controlSize)
    private var controlSize

    var iconEdge: HorizontalEdge

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: CapsuleButtonStyle.CapsuleControlMetrics(controlSize).labelSpacing) {
            if iconEdge == .leading {
                configuration.icon
            }

            configuration.title

            if iconEdge == .trailing {
                configuration.icon
            }
        }
    }
}
