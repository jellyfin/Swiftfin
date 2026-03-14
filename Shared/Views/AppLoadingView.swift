//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// The loading view for the app when migrations are taking place
struct AppLoadingView: View {

    @State
    private var didFailMigration = false

    var body: some View {
        ZStack {
            Color.clear

            if didFailMigration {
                ErrorView(error: ErrorMessage("An internal error occurred."))
            } else {
                ProgressView()
            }
        }
        // TODO: Implement failed migration recovery options
        /* .topBarTrailing {
             Button(L10n.advanced, systemImage: "gearshape.fill") {}
                 .foregroundStyle(.secondary)
                 .disabled(!didFailMigration)
                 .isVisible(didFailMigration)
                 .labelStyle(.iconOnly)
         } */
        .onNotification(.didFailMigration) { _ in
            didFailMigration = true
        }
    }
}
