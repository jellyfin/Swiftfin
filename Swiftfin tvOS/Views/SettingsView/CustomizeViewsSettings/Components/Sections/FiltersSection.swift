//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension CustomizeViewsSettings {

    struct FiltersSection: View {

        @Default(.Customization.Library.letterPickerEnabled)
        var letterPickerEnabled
        @Default(.Customization.Library.letterPickerOrientation)
        var letterPickerOrientation

        var body: some View {
            Section(L10n.filters) {

                Toggle(L10n.letterPicker, isOn: $letterPickerEnabled)

                if letterPickerEnabled {
                    InlineEnumToggle(
                        title: L10n.orientation,
                        selection: $letterPickerOrientation
                    )
                }
            }
        }
    }
}
