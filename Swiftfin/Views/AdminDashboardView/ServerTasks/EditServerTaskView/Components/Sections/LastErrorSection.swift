//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension EditServerTaskView {

    struct LastErrorSection: View {

        let message: String

        var body: some View {
            Section(L10n.errorDetails) {
                Text(message)
            }
        }
    }
}
