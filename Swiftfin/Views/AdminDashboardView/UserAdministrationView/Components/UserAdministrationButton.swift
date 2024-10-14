//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

extension UserAdministrationView {

    struct UserAdministrationButton: View {

        @Injected(\.currentUserSession)
        private var userSession: UserSession!

        @EnvironmentObject
        private var router: AdminDashboardCoordinator.Router

        @ObservedObject
        var observer: UserAdministrationObserver

        var body: some View {
            Button {
                router.route(to: \.userDetails, observer)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    UserProfileImage(observer: observer)
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(Rectangle())
                        .frame(width: 150, height: 150)

                    Text(observer.user.name ?? .emptyDash)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    TextPairView(
                        L10n.lastSeen,
                        value: Text(formatLastSeenDate(observer.user.lastActivityDate))
                    )
                    .font(.footnote)
                }
                .padding()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 2)
            }
            .background(Color(.systemGray).opacity(0.1))
            .foregroundStyle(.primary, .secondary)
        }

        // MARK: - Format Last Seen Date

        private func formatLastSeenDate(_ date: Date?) -> String {
            guard let date = date else {
                return L10n.never
            }

            let timeInterval = Date().timeIntervalSince(date)
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short

            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
}
