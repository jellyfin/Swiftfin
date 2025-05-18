//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OrnamentButton: View {
    let systemName: String
    var size: CGFloat = UIFont.preferredFont(forTextStyle: .headline).pointSize * 1.5
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .backport
                .fontWeight(.semibold)
                .imageScale(.small)
                .foregroundStyle(Color.accentColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        #if os(tvOS)
            .focusSection()
        #endif
    }
}
