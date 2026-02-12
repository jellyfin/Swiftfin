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

    init() {
        self.isIconOnly = false
    }

    fileprivate init(isIconOnly: Bool) {
        self.isIconOnly = isIconOnly
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon

            if !isIconOnly {
                configuration.title
            }

            ZStack {
                // Capture text font if icon only
                Text(" ")
                    .hidden()

                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
        .font(.footnote)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            ContainerRelativeShape()
                .fill(isHighlighted ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(ComplexSecondaryShapeStyle()))
                .opacity(0.5)
        }
        .overlay {
            ContainerRelativeShape()
                .stroke(isHighlighted ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(ComplexSecondaryShapeStyle()), lineWidth: 2)
        }
        .clipShape(.capsule)
        .containerShape(.capsule)
    }
}

extension LabelStyle where Self == NavigationDrawerLabelStyle {

    static var navigationDrawer: NavigationDrawerLabelStyle {
        NavigationDrawerLabelStyle(isIconOnly: false)
    }
}
