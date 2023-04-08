//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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
    private var showUnwatched
    @Default(.Customization.Indicators.showPlayed)
    private var showWatched

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

                Section {

                    Toggle("Show Favorited", isOn: $showFavorited)

                    Toggle("Show Progress", isOn: $showProgress)

                    Toggle("Show Unwatched", isOn: $showUnwatched)

                    Toggle("Show Watched", isOn: $showWatched)
                }
            }
            .withDescriptionTopPadding()
            .navigationTitle("Indicators")
    }
}
