//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct ConfirmCloseOverlay: View {

        var body: some View {
            ZStack {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 96))
                    .padding(3)
                    .background {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
