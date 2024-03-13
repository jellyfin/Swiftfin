//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SystemImageContentView: View {

    @State
    private var contentSize: CGSize = .zero

    private let systemName: String

    init(systemName: String?) {
        self.systemName = systemName ?? "circle"
    }

    var body: some View {
        ZStack {
            Color.secondarySystemFill
                .opacity(0.5)

            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
                .frame(width: contentSize.width / 3.5, height: contentSize.height / 3)
        }
        .size($contentSize)
    }
}
