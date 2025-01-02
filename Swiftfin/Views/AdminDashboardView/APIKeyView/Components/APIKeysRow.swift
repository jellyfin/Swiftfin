//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

extension APIKeysView {

    struct APIKeysRow: View {

        // MARK: - API Key Variables

        let apiKey: AuthenticationInfo

        // MARK: - API Key Actions

        let onSelect: () -> Void
        let onDelete: () -> Void

        // MARK: - Row Content

        @ViewBuilder
        private var rowContent: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(apiKey.appName ?? L10n.unknown)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text(apiKey.accessToken ?? L10n.unknown)
                    .lineLimit(2)

                TextPairView(
                    L10n.dateCreated,
                    value: {
                        if let creationDate = apiKey.dateCreated {
                            Text(creationDate, format: .dateTime)
                        } else {
                            Text(L10n.unknown)
                        }
                    }()
                )
                .monospacedDigit()
            }
            .font(.subheadline)
            .multilineTextAlignment(.leading)
        }

        // MARK: - Body

        var body: some View {
            Button(action: onSelect) {
                rowContent
            }
            .foregroundStyle(.primary, .secondary)
            .swipeActions {
                Button(
                    L10n.delete,
                    systemImage: "trash",
                    action: onDelete
                )
                .tint(.red)
            }
        }
    }
}
