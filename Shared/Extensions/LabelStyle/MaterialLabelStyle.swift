//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension LabelStyle where Self == MaterialLabelStyle {
    static var material: MaterialLabelStyle { MaterialLabelStyle() }
}

struct MaterialLabelStyle: LabelStyle {

    @Environment(\.isSelected)
    private var isSelected
    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Material.thin)

            HStack {
                configuration.icon
                    .foregroundColor(.secondary)
                configuration.title
            }
        }
    }
}
