//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct IndicatorSettingsView: View {

    @Default(.Customization.Indicators.enabled)
    private var indicators

    var body: some View {
        Form(systemImage: "checkmark.circle.fill") {
            Section(L10n.posters) {
                Toggle(L10n.showWatched, isOn: $indicators.contains(.played))

                Toggle(L10n.showFavorited, isOn: $indicators.contains(.favorited))

                Toggle(L10n.showProgress, isOn: $indicators.contains(.progress))

                Toggle(L10n.showUnwatched, isOn: $indicators.contains(.unplayed))
            }
            .navigationTitle(L10n.indicators)
        }
    }
}
