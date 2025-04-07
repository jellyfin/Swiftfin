//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import IdentifiedCollections
import JellyfinAPI
import SwiftUI

extension ServerActivityView {

    struct LogEntry: View {

        @Injected(\.currentUserSession)
        private var currentUserSession

        private let activityLogEntry: ActivityLogEntry
        private let users: IdentifiedArrayOf<UserDto>
        private let onSelect: () -> Void

        @Environment(\.colorScheme)
        private var colorScheme

        @State
        private var isExpanded = false

        init(_ activityLogEntry: ActivityLogEntry, users: IdentifiedArrayOf<UserDto>, onSelect: @escaping () -> Void) {
            self.activityLogEntry = activityLogEntry
            self.users = users
            self.onSelect = onSelect
        }

        private var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            return formatter
        }

        private var formattedDate: String {
            guard let date = activityLogEntry.date else { return L10n.unknown }
            return dateFormatter.string(from: date)
        }

        private var matchingUser: UserDto? {
            guard let userID = activityLogEntry.userID else { return nil }
            return users.first(where: { $0.id == userID })
        }

        private var userDisplayName: String {
            if let userName = matchingUser?.name {
                return userName
            } else if let userID = activityLogEntry.userID {
                return userID
            } else {
                return L10n.unknown
            }
        }

        var body: some View {
            Button(action: onSelect) {
                HStack {
                    if let client = currentUserSession?.client {
                        UserProfileImage(
                            userID: activityLogEntry.userID ?? currentUserSession?.user.id,
                            source: matchingUser?.profileImageSource(client: client, maxWidth: 60) ?? ImageSource()
                        ) {
                            SystemImageContentView(systemName: "gearshape.fill", ratio: 0.5)
                                .foregroundStyle(Color.accentColor)
                        }
                        .frame(width: 60, height: 60)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label {
                                Text(activityLogEntry.severity?.displayTitle ?? L10n.unknown)
                                    .font(.system(.subheadline, design: .monospaced))
                            } icon: {
                                Image(systemName: activityLogEntry.severity?.systemImage ?? "questionmark.circle")
                                    .foregroundColor(activityLogEntry.severity?.color ?? .gray)
                            }

                            Spacer()

                            if let type = activityLogEntry.type, !type.isEmpty {
                                Text(type)
                                    .font(.caption2)
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }

                        // Main content
                        if let name = activityLogEntry.name {
                            Text(name)
                                .font(.headline)
                                .lineLimit(1)
                        }

                        if let shortOverview = activityLogEntry.shortOverview, !shortOverview.isEmpty {
                            Text(shortOverview)
                                .font(.body)
                                .lineLimit(2)
                        }

                        // User and metadata row
                        HStack(spacing: 12) {
                            Text(matchingUser?.name ?? L10n.system)
                                .font(.caption)
                                .foregroundStyle(.primary)

                            Spacer()

                            Text(formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
