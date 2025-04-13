//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ServerActivityView {

    struct LogEntry: View {

        // MARK: - Activity Log Entry Variable

        @StateObject
        var viewModel: ServerActivityDetailViewModel

        // MARK: - Action Variable

        let action: () -> Void

        // MARK: - Body

        var body: some View {
            ListRow {
                userImage
            } content: {
                rowContent
                    .padding(.bottom, 8)
            }
            .onSelect(perform: action)
        }

        // MARK: - User Image

        @ViewBuilder
        private var userImage: some View {
            let imageSource = viewModel.user?.profileImageSource(client: viewModel.userSession.client, maxWidth: 60) ?? .init()

            UserProfileImage(
                userID: viewModel.log.userID ?? viewModel.userSession?.user.id,
                source: imageSource
            ) {
                SystemImageContentView(
                    systemName: viewModel.user != nil ? "person.fill" : "gearshape.fill",
                    ratio: 0.5
                )
            }
            .frame(width: 60, height: 60)
        }

        // MARK: - User Image

        @ViewBuilder
        private var rowContent: some View {
            HStack {
                VStack(alignment: .leading) {
                    /// Event Severity & Username / System
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.log.severity?.systemImage ?? "questionmark.circle")
                            .foregroundStyle(viewModel.log.severity?.color ?? .gray)

                        if viewModel.user != nil {
                            Text(viewModel.user?.name ?? L10n.unknown)
                        } else {
                            Text(L10n.system)
                        }
                    }
                    .font(.headline)

                    /// Event Name
                    Text(viewModel.log.name ?? .emptyDash)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Group {
                        if let eventDate = viewModel.log.date {
                            Text(eventDate.formatted(date: .abbreviated, time: .standard))
                        } else {
                            Text(String.emptyTime)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
