//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SettingsHelpText: View {
    var header: String
    var bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(header)
                .font(.headline)
            Text(bodyText)
                .font(.body)
        }
        .padding()
    }
}
