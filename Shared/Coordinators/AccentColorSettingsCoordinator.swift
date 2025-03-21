//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI

// UserProfileImageCoordinator
final class AccentColorSettingsCoordinator: NavigationCoordinatable {

    // MARK: - Navigation Stack

    let stack = Stinsen.NavigationStack(initial: \AccentColorSettingsCoordinator.start)

    @Root
    var start = makeStart

    @ViewBuilder
    func makeStart() -> some View {
        AccentColorSettingsView()
    }
}
