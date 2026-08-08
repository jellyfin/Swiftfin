//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct EPGTypeMenu: View {

    @Default(.accentColor)
    private var accentColor
    @Default(.Customization.EPG.programColorSelection)
    private var selectedTypes

    @FocusState
    private var isFocused: Bool

    var body: some View {
        Menu(L10n.type, systemImage: "paintpalette") {
            ForEach(ProgramType.allCases) { type in
                Toggle(type.displayTitle, isOn: $selectedTypes.contains(type))
            }
        }
        #if os(tvOS)
        .menuStyle(.button)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backport
        .glassEffect(
            .regular.selection(
                tint: isFocused ? accentColor : nil,
                foregroundColor: isFocused ? accentColor.overlayColor : .primary
            )
            .interactive(false),
            in: .capsule
        )
        .focused($isFocused)
        #endif
    }
}
