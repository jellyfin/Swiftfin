//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayerSettingsView {
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
            Form {
                Section {
                    Picker(L10n.mediaSegmentIntro, selection: $introAction) {
                        Text(L10n.mediaSegmentActionIgnore).tag(MediaSegmentAction.ignore)
                        Text(L10n.mediaSegmentActionAsk).tag(MediaSegmentAction.ask)
                        Text(L10n.mediaSegmentActionSkip).tag(MediaSegmentAction.skip)
                    }
                    Picker(L10n.mediaSegmentOutro, selection: $outroAction) {
                        Text(L10n.mediaSegmentActionIgnore).tag(MediaSegmentAction.ignore)
                        Text(L10n.mediaSegmentActionAsk).tag(MediaSegmentAction.ask)
                        Text(L10n.mediaSegmentActionSkip).tag(MediaSegmentAction.skip)
                    }
                    Picker(L10n.mediaSegmentPreview, selection: $previewAction) {
                        Text(L10n.mediaSegmentActionIgnore).tag(MediaSegmentAction.ignore)
                        Text(L10n.mediaSegmentActionAsk).tag(MediaSegmentAction.ask)
                        Text(L10n.mediaSegmentActionSkip).tag(MediaSegmentAction.skip)
                    }
                    Picker(L10n.mediaSegmentRecap, selection: $recapAction) {
                        Text(L10n.mediaSegmentActionIgnore).tag(MediaSegmentAction.ignore)
                        Text(L10n.mediaSegmentActionAsk).tag(MediaSegmentAction.ask)
                        Text(L10n.mediaSegmentActionSkip).tag(MediaSegmentAction.skip)
                    }
                    Picker(L10n.mediaSegmentCommercial, selection: $commercialAction) {
                        Text(L10n.mediaSegmentActionIgnore).tag(MediaSegmentAction.ignore)
                        Text(L10n.mediaSegmentActionAsk).tag(MediaSegmentAction.ask)
                        Text(L10n.mediaSegmentActionSkip).tag(MediaSegmentAction.skip)
                    }
                }
            }
            .navigationTitle(L10n.configureMediaSegments)
        }
    }
}
