//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct NavigationDrawerLabelStyle: LabelStyle {

    @Environment(\.isSelected)
    private var isSelected

    private let isIconOnly: Bool

    var iconOnly: NavigationDrawerLabelStyle {
        NavigationDrawerLabelStyle(isIconOnly: true)
    }

    init() {
        self.isIconOnly = false
    }

    fileprivate init(isIconOnly: Bool) {
        self.isIconOnly = isIconOnly
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            Group {
                configuration.icon

                if !isIconOnly {
                    configuration.title
                }
            }
            .fontWeight(.semibold)

            ZStack {
                // Capture text font if icon only
                Text(" ")
                    .hidden()

                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
        .font(.footnote)
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .fill(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(ComplexSecondaryShapeStyle()))
                .opacity(0.5)
        }
        .overlay {
            Capsule()
                .stroke(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(ComplexSecondaryShapeStyle()), lineWidth: 1)
        }
    }
}

extension LabelStyle where Self == NavigationDrawerLabelStyle {

    static var navigationDrawer: NavigationDrawerLabelStyle {
        NavigationDrawerLabelStyle(isIconOnly: false)
    }
}
