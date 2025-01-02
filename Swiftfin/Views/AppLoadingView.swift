//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// The loading view for the app when migrations are taking place
struct AppLoadingView: View {

    @State
    private var didFailMigration = false

    var body: some View {
        ZStack {
            Color.clear

            if !didFailMigration {
                DelayedProgressView()
            }

            if didFailMigration {
                ErrorView(error: JellyfinAPIError("An internal error occurred."))
            }
        }
        .topBarTrailing {
            Button(L10n.advanced, systemImage: "gearshape.fill") {}
                .foregroundStyle(.secondary)
                .disabled(true)
                .opacity(didFailMigration ? 0 : 1)
        }
        .onNotification(.didFailMigration) { _ in
            didFailMigration = true
        }
    }
}
