//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct RemotePlaybackSessionView: View {

    let route: RemotePlaybackRoute
    let deviceName: String?

    var body: some View {
        ZStack {
            Color.black

            ContentUnavailableView(
                L10n.playingOnDevice(deviceName ?? route.displayTitle),
                systemImage: route.systemImage
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
