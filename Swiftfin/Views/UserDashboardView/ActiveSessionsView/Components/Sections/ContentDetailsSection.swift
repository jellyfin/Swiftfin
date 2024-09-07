//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ActiveSessionRowView {
    struct ContentDetailsSection: View {

        let itemOverview: String?
        let sourceWidth: Int?
        let sourceHeight: Int?

        init(session: SessionInfo) {
            self.itemOverview = session.nowPlayingItem?.overview
            self.sourceWidth = session.nowPlayingItem?.width
            self.sourceHeight = session.nowPlayingItem?.height
        }

        var body: some View {
            VStack(spacing: 8) {
                if let sourceWidth = sourceWidth, let sourceHeight = sourceHeight {
                    Text("\(sourceWidth.description)x\(sourceHeight.description)")
                        .foregroundColor(.secondary)
                }

                if let itemOverview = itemOverview {
                    Text(itemOverview)
                }
            }
        }
    }
}
