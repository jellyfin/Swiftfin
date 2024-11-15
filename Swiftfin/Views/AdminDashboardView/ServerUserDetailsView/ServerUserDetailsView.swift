//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserDetailsView: View {

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @CurrentDate
    private var currentDate: Date

    @StateObject
    private var viewModel: ServerUserAdminViewModel

    // MARK: - Initializer

    init(user: UserDto) {
        _viewModel = StateObject(wrappedValue: ServerUserAdminViewModel(user: user))
    }

    // MARK: - Body

    var body: some View {
        List {
            AdminDashboardView.UserSection(
                user: viewModel.user,
                lastActivityDate: viewModel.user.lastActivityDate
            )

            Section(L10n.advanced) {
                if let userId = viewModel.user.id {
                    ChevronButton(L10n.password)
                        .onSelect {
                            router.route(to: \.resetUserPassword, userId)
                        }
                }
            }
        }
        .navigationTitle(L10n.user)
        .onAppear {
            viewModel.send(.loadDetails)
        }
    }
}
