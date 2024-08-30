//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: will be entirely re-organized

struct CustomizeViewsSettings: View {
    @Default(.Customization.showRecentlyAdded)
    private var showRecentlyAdded

    var body: some View {
        List {
            CustomizeItemSection()

            CustomizeFilterSection()

            CustomizePosterSection()

            CustomizeLibrarySection()

            Section("Home") {
                Toggle("Show recently added", isOn: $showRecentlyAdded)
            }
        }
        .navigationTitle(L10n.customize)
    }
}
