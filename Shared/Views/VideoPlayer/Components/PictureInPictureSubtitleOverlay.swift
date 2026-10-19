//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PictureInPictureSubtitleOverlay: View {

    let presentation: TextSubtitlePresentation

    var body: some View {
        GeometryReader { geometry in
            // Read the shared model inside the rasterized view. Captured snapshots
            // would stop updating when the inline SwiftUI hierarchy is inactive.
            if let snapshot = presentation.snapshot {
                TextSubtitleOverlay(
                    snapshot: snapshot,
                    videoLayout: VideoPlayer.VideoLayout(
                        videoSize: geometry.size,
                        viewportSize: geometry.size,
                        behavior: .fit
                    ),
                    reportCaptions: nil
                )
            }
        }
    }
}
