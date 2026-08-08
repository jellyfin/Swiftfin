//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct EPGColorSettingsView: View {

    @Default(.Customization.EPG.programColor)
    private var typeColors

    private func binding(for type: ProgramType) -> Binding<Color> {
        Binding(
            get: { typeColors[type] ?? type.color },
            set: { typeColors[type] = $0 }
        )
    }

    var body: some View {
        Form(systemImage: "paintpalette") {
            Section(L10n.color) {
                ForEach(ProgramType.allCases) { type in
                    ColorPicker(
                        type.displayTitle,
                        selection: binding(for: type),
                        supportsOpacity: false
                    )
                }
            }
        }
        .navigationTitle(L10n.guide)
    }
}
