//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct RemoteButton: View {

    @Environment(\.isEnabled)
    private var isEnabled

    let systemImage: String
    var size: CGFloat = 60
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(size > 60 ? .title : .title2)
                .frame(width: size, height: size)
                .backport
                .glassEffect(
                    .regular.selection(
                        tint: .secondarySystemBackground,
                        foregroundColor: .primary
                    ),
                    in: .circle
                )
        }
        .buttonStyle(BasicHoverButtonStyle())
        .opacity(isEnabled ? 1 : 0.5)
    }
}
