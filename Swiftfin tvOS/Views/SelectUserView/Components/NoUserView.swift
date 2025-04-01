//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SelectUserView {

    struct NoUserView: View {
        var body: some View {
            VStack {
                ZStack {
                    Color.secondarySystemFill

                    RelativeSystemImageView(systemName: "person")
                }
                .clipShape(.circle)
                .aspectRatio(1, contentMode: .fill)
                .opacity(0.5)

                Text(L10n.login)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
    }
}
