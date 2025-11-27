//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct MediaSegmentSettingsView: View {

    #if os(tvOS)
    typealias PlatformPicker = ListRowMenu
    #else
    typealias PlatformPicker = Picker
    #endif

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
        Form(systemImage: "forward.end") {
            Section {
                PlatformPicker(L10n.mediaSegmentIntro, selection: $introAction)
                PlatformPicker(L10n.mediaSegmentOutro, selection: $outroAction)
                PlatformPicker(L10n.mediaSegmentPreview, selection: $previewAction)
                PlatformPicker(L10n.mediaSegmentRecap, selection: $recapAction)
                PlatformPicker(L10n.mediaSegmentCommercial, selection: $commercialAction)
            } header: {
                Text(L10n.mediaSegments)
            }
        }
        .navigationTitle(L10n.configureMediaSegments)
    }
}
