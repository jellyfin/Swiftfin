//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension SelectUserView {

    struct ConnectToJellyfinView: View {

        @Default(.accentColor)
        private var accentColor

        @Router
        private var router

        var body: some View {
            VStack {
                Text(L10n.connectToJellyfinServerStart)
                    .multilineTextAlignment(.center)

                Button(L10n.connect) {
                    router.route(to: .connectToServer)
                }
                .foregroundStyle(
                    accentColor.overlayColor,
                    accentColor
                )
                .buttonStyle(.primary)
                .frame(
                    height: UIDevice.isTV ? 75 : 44
                )
            }
            .frame(maxWidth: UIDevice.isTV ? 400 : 250)
        }
    }
}
