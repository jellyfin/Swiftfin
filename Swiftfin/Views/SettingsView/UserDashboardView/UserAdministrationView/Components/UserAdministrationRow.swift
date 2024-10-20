//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Factory
import JellyfinAPI
import SwiftUI

extension UserAdministrationView {
    struct UserAdministrationRow: View {
        @Injected(\.currentUserSession)
        private var userSession: UserSession!

        @EnvironmentObject
        private var router: SettingsCoordinator.Router

        @ObservedObject
        var observer: UserAdministrationObserver

        // MARK: - Body

        var body: some View {
            Button {
                router.route(to: \.userDetails, observer)
            } label: {
                VStack(spacing: 8) {
                    HStack {
                        UserProfileImage(observer: observer)
                            .frame(width: 60, height: 60)
                        VStack(alignment: .leading) {
                            Text(observer.user.name ?? L10n.unknown)
                                .foregroundStyle(.foreground)
                                .font(.headline)
                            Spacer()
                            TextPairView(
                                L10n.lastSeen,
                                value: Text(formatLastSeenDate(observer.user.lastActivityDate))
                            )
                        }
                    }
                    Divider()
                }
            }
        }

        // MARK: - Format Last Seen Date

        private func formatLastSeenDate(_ date: Date?) -> String {
            guard let date = date else {
                return "Never" // L10n.never
            }

            let timeInterval = Date().timeIntervalSince(date)
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short

            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
}
