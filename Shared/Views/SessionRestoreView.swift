//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SessionRestoreView: View {

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.4)

            Text("Restoring Session…")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)

            Text("Please keep the app open while we reconnect to your server.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.secondary)
                .frame(maxWidth: 360)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
    }
}
