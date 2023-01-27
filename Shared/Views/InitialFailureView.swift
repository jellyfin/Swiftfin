//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct InitialFailureView: View {

    let initials: String

    init(_ initials: String) {
        self.initials = initials
    }

    var body: some View {
        ZStack {
            Color.secondarySystemFill
                .opacity(0.5)

            Text(initials)
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
    }
}
