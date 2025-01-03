//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ListRowCheckbox: View {

    @Default(.accentColor)
    private var accentColor

    // MARK: - Environment Variables

    @Environment(\.isEditing)
    private var isEditing
    @Environment(\.isSelected)
    private var isSelected

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        if isEditing, isSelected {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .backport
                .fontWeight(.bold)
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 24, height: 24)
                .symbolRenderingMode(.palette)
                .foregroundStyle(accentColor.overlayColor, accentColor)

        } else if isEditing {
            Image(systemName: "circle")
                .resizable()
                .backport
                .fontWeight(.bold)
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(.secondary)
        }
    }
}
