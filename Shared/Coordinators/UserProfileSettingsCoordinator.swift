//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

final class UserProfileSettingsCoordinator: NavigationCoordinatable {

    // MARK: - Navigation Components

    let stack = Stinsen.NavigationStack(initial: \UserProfileSettingsCoordinator.start)

    @Root
    var start = makeStart

    // MARK: - Route to User Profile Security

    @Route(.modal)
    var localSecurity = makeLocalSecurity

    // MARK: - Observed Object

    @ObservedObject
    var viewModel: SettingsViewModel

    // MARK: - Initializer

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - User Security View

    func makeLocalSecurity() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator(
            BasicNavigationViewCoordinator {
                UserLocalSecurityView()
            }
        )
    }

    @ViewBuilder
    func makeStart() -> some View {
        UserProfileSettingsView(viewModel: viewModel)
    }
}
