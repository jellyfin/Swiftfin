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

struct ServerActivityDetailsView: View {

    // MARK: - Dismiss

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - View Model

    @StateObject
    private var usersViewModel = ServerUsersViewModel()

    // MARK: - Activity Log Entry Variable

    private let logEntry: ActivityLogEntry

    // MARK: - Initializer

    init(_ logEntry: ActivityLogEntry) {
        self.logEntry = logEntry
    }

    // MARK: - Formatted Date

    private var eventDate: String {
        guard let date = logEntry.date else { return L10n.unknown }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Body

    var body: some View {
        List {
            Section(L10n.overview) {
                if let name = logEntry.name, !name.isEmpty {
                    Text(name)
                }
            }

            Section(L10n.details) {
                TextPairView(
                    leading: "Date",
                    trailing: eventDate
                )
                if let type = logEntry.type {
                    TextPairView(
                        leading: L10n.type,
                        trailing: type
                    )
                }
            }

            Section {
                if let overview = logEntry.overview, !overview.isEmpty {
                    Text(overview)
                } else if let shortOverview = logEntry.shortOverview, !shortOverview.isEmpty {
                    Text(shortOverview)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(logEntry.severity?.displayTitle ?? L10n.details)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            dismiss()
        }
        .onFirstAppear {
            usersViewModel.send(.getUsers())
        }
    }
}
