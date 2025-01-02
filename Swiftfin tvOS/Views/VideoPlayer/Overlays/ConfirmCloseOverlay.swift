//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ConfirmCloseOverlay: View {
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 96))
                    .padding(3)
                    .background(Color.black.opacity(0.4).mask(Circle()))

                Spacer()
            }
            .padding()

            Spacer()
        }
        .padding()
    }
}
