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
    private var router: SettingsCoordinator.Router

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
            UserDashboardView.UserSection(
                user: viewModel.user,
                lastActivityDate: viewModel.user.lastActivityDate
            )
        }
        .navigationTitle(L10n.user)
        .onAppear {
            viewModel.send(.loadDetails)
        }
    }
}
