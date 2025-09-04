//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct NavigationBar: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                if let subtitle = manager.item.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }

                HStack {
                    Text(manager.item.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ActionButtons()
                }
            }
        }
    }
}
