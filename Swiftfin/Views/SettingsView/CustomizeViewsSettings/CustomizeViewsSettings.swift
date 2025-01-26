//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CustomizeViewsSettings: View {

    var body: some View {
        List {
            HomeSection()

            LibrarySection()

            PosterSection()

            FilterSection()

            ItemSection()

            HomeSection()

            Section {
                Toggle(L10n.rememberLayout, isOn: $rememberLibraryLayout)
            } footer: {
                Text(L10n.rememberLayoutFooter)
            }

            Section {
                Toggle(L10n.rememberSorting, isOn: $rememberLibrarySort)
            } footer: {
                Text(L10n.rememberSortingFooter)
            }

            Section {
                Toggle(L10n.seriesBackdrop, isOn: $useSeriesLandscapeBackdrop)
            } header: {
                // TODO: think of a better name
                L10n.episodeLandscapePoster.text
            }
        }
        .navigationTitle(L10n.customize)
    }
}
