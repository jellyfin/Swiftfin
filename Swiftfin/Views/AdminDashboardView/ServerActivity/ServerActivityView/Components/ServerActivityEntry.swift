//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import IdentifiedCollections
import JellyfinAPI
import SwiftUI

extension ServerActivityView {

    struct LogEntry: View {

        // MARK: - Current User Session

        @Injected(\.currentUserSession)
        private var currentUserSession

        // MARK: - Activity Log Entry Variable

        private let logEntry: ActivityLogEntry

        // MARK: - All Server Users

        private let users: IdentifiedArrayOf<UserDto>

        // MARK: - Action Variable

        private let onSelect: () -> Void

        // MARK: - Initializer

        init(_ logEntry: ActivityLogEntry, users: IdentifiedArrayOf<UserDto>, onSelect: @escaping () -> Void) {
            self.logEntry = logEntry
            self.users = users
            self.onSelect = onSelect
        }

        // MARK: - Matching UserDto

        private var eventDate: String {
            guard let date = logEntry.date else { return L10n.unknown }

            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium

            return formatter.string(from: date)
        }

        // MARK: - Matching UserDto

        private var eventUser: UserDto? {
            guard let userID = logEntry.userID else { return nil }
            return users.first(where: { $0.id == userID })
        }

        // MARK: - Body

        var body: some View {
            ListRow {
                userImage
            } content: {
                rowContent
                    .padding(.bottom, 8)
            }
            .onSelect(perform: onSelect)
        }

        // MARK: - User Image

        @ViewBuilder
        private var userImage: some View {
            if let client = currentUserSession?.client {
                UserProfileImage(
                    userID: logEntry.userID ?? currentUserSession?.user.id,
                    source: eventUser?.profileImageSource(client: client, maxWidth: 60) ?? ImageSource()
                ) {
                    SystemImageContentView(systemName: "gearshape.fill", ratio: 0.5)
                        .foregroundStyle(Color.accentColor)
                }
                .frame(width: 60, height: 60)
            }
        }

        // MARK: - User Image

        private var rowContent: some View {
            HStack {
                VStack(alignment: .leading) {
                    /// Event Severity & Username / System
                    HStack(spacing: 8) {
                        Image(systemName: logEntry.severity?.systemImage ?? "questionmark.circle")
                            .foregroundStyle(logEntry.severity?.color ?? .gray)

                        Text(eventUser?.name ?? L10n.system)
                            .foregroundStyle(.primary)
                    }
                    .font(.headline)

                    /// Event Name
                    Text(logEntry.name ?? .emptyDash)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    /// Event Date
                    Text(eventDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .padding()
                    .font(.body.weight(.regular))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
