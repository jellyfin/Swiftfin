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
    struct SliderSection: View {

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider

        @StoredValue(.User.previewImageScrubbing)
        private var previewImageScrubbing: PreviewImageScrubbingOption

        var body: some View {
            Section(L10n.slider) {

                Toggle(L10n.chapterSlider, isOn: $chapterSlider)

                CaseIterablePicker(
                    L10n.previewImage,
                    selection: $previewImageScrubbing
                )
            }
        }
    }
}
