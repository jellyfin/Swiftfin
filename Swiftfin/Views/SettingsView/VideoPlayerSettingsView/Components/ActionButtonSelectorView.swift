//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ActionButtonSelectorView: View {

    @Binding
    var selection: [VideoPlayerActionButton]

    var body: some View {
        OrderedSectionSelectorView(
            selection: $selection,
            sources: VideoPlayerActionButton.allCases
        )
        .label { button in
            HStack {
                Image(systemName: button.settingsSystemImage)

                Text(button.displayTitle)
            }
        }
    }
}
