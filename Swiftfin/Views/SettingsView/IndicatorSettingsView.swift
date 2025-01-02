//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: show a sample poster to model indicators

struct IndicatorSettingsView: View {

    @Default(.Customization.Indicators.showFavorited)
    private var showFavorited
    @Default(.Customization.Indicators.showProgress)
    private var showProgress
    @Default(.Customization.Indicators.showUnplayed)
    private var showUnplayed
    @Default(.Customization.Indicators.showPlayed)
    private var showPlayed

    var body: some View {
        Form {
            Section {

                Toggle(L10n.favorited, isOn: $showFavorited)

                Toggle(L10n.progress, isOn: $showProgress)

                Toggle(L10n.unplayed, isOn: $showUnplayed)

                Toggle(L10n.played, isOn: $showPlayed)
            }
        }
        .navigationTitle(L10n.indicators)
    }
}
