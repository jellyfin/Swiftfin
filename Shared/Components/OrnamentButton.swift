//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

/// https://developer.apple.com/design/human-interface-guidelines/ornaments
struct OrnamentButton: View {

    // MARK: - Accent Color

    @Default(.accentColor)
    private var accentColor

    // MARK: - Required Configuration

    let systemName: String

    // MARK: - Optional Configuration

    var size: CGFloat = UIFont.preferredFont(forTextStyle: .headline).pointSize * 1.5
    var action: () -> Void = {}

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .backport
                .fontWeight(.semibold)
                .imageScale(.small)
                .foregroundStyle(accentColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(.regularMaterial)
                )
                .contentShape(Circle())
                .posterShadow()
        }
        .buttonStyle(.plain)
    }
}
