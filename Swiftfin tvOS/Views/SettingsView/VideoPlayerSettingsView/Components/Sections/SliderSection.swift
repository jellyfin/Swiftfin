//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayerSettingsView {
    struct SliderSection: View {
        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider
        @Default(.VideoPlayer.Overlay.sliderColor)
        private var sliderColor
        @Default(.VideoPlayer.Overlay.sliderType)
        private var sliderType

        var body: some View {
            Section {
                Toggle(L10n.chapterSlider, isOn: $chapterSlider)

                // Commenting since ColorPicker is not around on tvOS. May need to be recreated manually?
                /* ColorPicker(selection: $sliderColor, supportsOpacity: false) {
                     Text(L10n.sliderColor)
                 } */

                InlineEnumToggle(title: L10n.sliderType, selection: $sliderType)
            } header: {
                L10n.slider.text
            } footer: {
                L10n.sliderDescription.text
            }
        }
    }
}
