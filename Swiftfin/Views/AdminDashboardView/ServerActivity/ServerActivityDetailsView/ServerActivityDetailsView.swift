//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ServerActivityDetailsView: View {

    // MARK: - Environment Objects

    @Router
    private var router

    // MARK: - Activity Log Entry Variable

    @StateObject
    var viewModel: ServerActivityDetailViewModel

    // MARK: - Body

    var body: some View {
        List {
            /// Item (If Available)
            if let item = viewModel.item {
                AdminDashboardView.MediaItemSection(item: item)
            }

            /// User (If Available)
            if let user = viewModel.user {
                AdminDashboardView.UserSection(
                    user: user,
                    lastActivityDate: viewModel.log.date
                ) {
                    router.route(to: .userDetails(user: user))
                }
            }

            /// Event Name & Overview
            Section(L10n.overview) {
                if let name = viewModel.log.name, name.isNotEmpty {
                    Text(name)
                }
                if let overview = viewModel.log.overview, overview.isNotEmpty {
                    Text(overview)
                } else if let shortOverview = viewModel.log.shortOverview, shortOverview.isNotEmpty {
                    Text(shortOverview)
                }
            }

            /// Event Details
            Section(L10n.details) {
                if let severity = viewModel.log.severity {
                    LabeledContent(
                        L10n.level,
                        value: severity.displayTitle
                    )
                }
                if let type = viewModel.log.type {
                    LabeledContent(
                        L10n.type,
                        value: type
                    )
                }
                if let date = viewModel.log.date {
                    LabeledContent(
                        L10n.date,
                        value: date.formatted(date: .long, time: .shortened)
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(
            L10n.activityLog
                .localizedCapitalized
        )
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.refresh()
        }
    }
}
