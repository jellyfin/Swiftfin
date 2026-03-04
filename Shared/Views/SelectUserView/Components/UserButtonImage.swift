//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SelectUserView {

    struct UserButtonImage: View {

        private let item: UserItem?

        init(_ item: UserItem? = nil) {
            self.item = item
        }

        var body: some View {
            if let item {
                UserProfileImage(
                    userID: item.user.id,
                    source: item.user.profileImageSource(
                        client: item.server.client
                    ),
                    pipeline: .Swiftfin.local
                )
                .posterShadow()
            } else {
                RelativeSystemImageView(systemName: "plus")
                    .foregroundStyle(Color.secondary)
                    .background(.thinMaterial)
                    .clipShape(.circle)
                    .aspectRatio(1, contentMode: .fit)
                    .posterShadow()
            }
        }
    }
}
