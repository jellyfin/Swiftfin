//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActiveDevicesView {

    struct ConnectionSection: View {

        let lastActivityDate: Date
        let currentDate: Date
        let prefixText: Bool

        // MARK: - Body

        var body: some View {
            if prefixText {
                lastSeenDateView
            } else {
                lastSeenTextView
            }
        }

        // MARK: - Last Seen Description

        @ViewBuilder
        private var lastSeenTextView: some View {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return Text(
                formatter.localizedString(
                    for: lastActivityDate,
                    relativeTo: currentDate
                )
            )
        }

        // MARK: - Last Seen Date

        @ViewBuilder
        private var lastSeenDateView: some View {
            HStack {
                Text(L10n.lastSeenWithString(""))
                Spacer()
                Text(
                    lastActivityDate
                        .formatted(
                            .dateTime.year().month().day().hour().minute()
                        )
                )
                .foregroundColor(.secondary)
            }
        }
    }
}
