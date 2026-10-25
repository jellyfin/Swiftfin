//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SystemSettingsButton: View {

    let title: String
    let destination: SystemSettings

    @State
    private var error: Error?

    var body: some View {
        ChevronButton(title, external: true) {
            Task {
                do {
                    try await destination.open()
                } catch {
                    self.error = error
                }
            }
        }
        .errorMessage($error)
    }
}
