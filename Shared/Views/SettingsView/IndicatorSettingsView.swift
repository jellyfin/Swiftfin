//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct IndicatorSettingsView: PlatformView {

    @Default(.Customization.Indicators.showUnplayed)
    private var showUnplayed

    @Default(.Customization.Indicators.showPlayed)
    private var showPlayed
    @Default(.Customization.Indicators.showFavorited)
    private var showFavorited
    @Default(.Customization.Indicators.showProgress)
    private var showProgress

    var iOSView: some View {
        Form {
            contentView
        }
    }

    var tvOSView: some View {
        #if os(tvOS)
        SplitFormWindowView()
            .descriptionView {
                // TODO: On tvOS - Show a sample poster to model indicators
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                contentView
            }
        #endif
    }

    private var contentView: some View {
        Section(L10n.posters) {

            #if os(tvOS)
            ListRowMenu(L10n.showUnwatched, selection: $showUnplayed)
            #else
            Picker(L10n.showUnwatched, selection: $showUnplayed) {
                ForEach(UnplayedIndicatorType.allCases) { option in
                    Text(option.displayTitle).tag(option)
                }
            }
            #endif

            Toggle(L10n.showWatched, isOn: $showPlayed)

            Toggle(L10n.showFavorited, isOn: $showFavorited)

            Toggle(L10n.showProgress, isOn: $showProgress)
        }
        .navigationTitle(L10n.indicators)
    }
}
