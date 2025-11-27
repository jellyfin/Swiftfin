//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct MediaSegmentSettingsView: View {

    @Default(.VideoPlayer.introAction)
    private var introAction
    @Default(.VideoPlayer.outroAction)
    private var outroAction
    @Default(.VideoPlayer.previewAction)
    private var previewAction
    @Default(.VideoPlayer.recapAction)
    private var recapAction
    @Default(.VideoPlayer.commercialAction)
    private var commercialAction

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "tv")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                ListRowMenu(L10n.mediaSegmentIntro, selection: $introAction)
                ListRowMenu(L10n.mediaSegmentOutro, selection: $outroAction)
                ListRowMenu(L10n.mediaSegmentPreview, selection: $previewAction)
                ListRowMenu(L10n.mediaSegmentRecap, selection: $recapAction)
                ListRowMenu(L10n.mediaSegmentCommercial, selection: $commercialAction)
            }
            .navigationTitle(L10n.configureMediaSegments)
    }
}
