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
    struct ConnectionSection: View {
        let lastActivityDate: Date?

        init(session: SessionInfo) {
            self.lastActivityDate = session.lastActivityDate
        }

        private var lastSeenText: String {
            guard let lastActivityDate = lastActivityDate else {
                return ""
            }
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: lastActivityDate, relativeTo: Date())
        }

        var body: some View {
            if lastActivityDate != nil {
                Text(lastSeenText)
            } else {
                EmptyView()
            }
        }
    }
}
