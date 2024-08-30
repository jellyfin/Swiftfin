//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct SubtitleSizePickerView: View {

    @Binding
    var selection: Int

    var body: some View {
        StepperView(
            title: L10n.subtitleSize,
            value: $selection,
            range: 8 ... 24,
            step: 1
        )
    }
}
