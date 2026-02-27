//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ListRowCheckbox: View {

    @Default(.accentColor)
    private var accentColor

    @Environment(\.isEditing)
    private var isEditing
    @Environment(\.isSelected)
    private var isSelected

    private let showDeselected: Bool

    #if os(tvOS)
    private let size: CGFloat = 36
    #else
    private let size: CGFloat = 24
    #endif

    init(showDeselected: Bool = true) {
        self.showDeselected = showDeselected
    }

    @ViewBuilder
    var body: some View {
        if isEditing, isSelected {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .fontWeight(.bold)
                .aspectRatio(1, contentMode: .fit)
                .frame(width: size, height: size)
                .symbolRenderingMode(.palette)
                .foregroundStyle(accentColor.overlayColor, accentColor)

        } else if isEditing, showDeselected {
            Image(systemName: "circle")
                .resizable()
                .fontWeight(.bold)
                .aspectRatio(1, contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(Color.secondary)
        }
    }
}
