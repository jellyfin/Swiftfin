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

    struct InitialSetupView: View {

        @Router
        private var router

        @Default(.accentColor)
        private var accentColor

        private var maxWidth: CGFloat {
            UIDevice.isTV ? 500 : 250
        }

        var body: some View {
            VStack(spacing: UIDevice.isTV ? 50 : 10) {
                Text(L10n.connectToJellyfinServerStart)
                    .font(.body)
                    .frame(minWidth: 50, maxWidth: maxWidth)
                    .multilineTextAlignment(.center)

                Button {
                    router.route(to: .connectToServer)
                } label: {
                    Text(L10n.connect)
                        .font(.callout)
                        .fontWeight(.bold)
                }
                .foregroundStyle(
                    accentColor.overlayColor,
                    accentColor
                )
                .buttonStyle(.primary)
                .frame(
                    width: maxWidth,
                    height: UIDevice.isTV ? 75 : 50
                )
            }
        }
    }
}
