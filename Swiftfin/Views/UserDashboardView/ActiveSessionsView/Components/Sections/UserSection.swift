//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActiveSessionsView {
    struct UserSection: View {
        let userName: String
        let device: String

        init(session: SessionInfo) {
            self.userName = session.userName ?? ""
            self.device = session.client ?? L10n.unknown
        }

        var body: some View {
            HStack {
                // TODO: Maybe add the user's icon / profile picture
                Text(userName)
                Spacer()
                Text(device)
            }
            .font(.headline)
        }
    }
}
