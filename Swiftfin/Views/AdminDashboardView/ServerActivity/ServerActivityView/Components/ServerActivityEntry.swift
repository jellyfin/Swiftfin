//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ServerActivityView {

    struct LogEntry: View {

        @StateObject
        var viewModel: ServerActivityDetailViewModel

        let action: () -> Void

        var body: some View {
            ChevronButton(action: action) {
                LabeledContent {
                    rowContent
                } label: {
                    userImage
                        .frame(width: 60, height: 60)
                }
            }
        }

        @ViewBuilder
        private var userImage: some View {
            if let user = viewModel.user {
                UserProfileImage(
                    userID: user.id,
                    source: user.profileImageSource(
                        client: viewModel.userSession.client,
                        maxWidth: 60
                    )
                )
            } else {
                ZStack {
                    Rectangle()
                        .fill(.complexSecondary)

                    SystemImageContentView(
                        systemName: "gearshape.fill",
                        ratio: 0.5
                    )
                }
                .posterBorder()
                .clipShape(.circle)
                .aspectRatio(1, contentMode: .fit)
                .shadow(radius: 5)
            }
        }

        @ViewBuilder
        private var rowContent: some View {
            HStack {
                VStack(alignment: .leading) {

                    /// Event Severity & Username / System
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.log.severity?.systemImage ?? LogLevel.none.systemImage)
                            .foregroundStyle(viewModel.log.severity?.color ?? LogLevel.none.color)

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

                    Text(viewModel.log.date?.formatted(date: .abbreviated, time: .standard) ?? .emptyRuntime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
        }
    }
}
