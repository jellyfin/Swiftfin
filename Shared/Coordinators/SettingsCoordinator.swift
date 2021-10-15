//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import Stinsen
import SwiftUI

final class SettingsCoordinator: NavigationCoordinatable {
    
    let stack = NavigationStack(initial: \SettingsCoordinator.start)

    @Root var start = makeStart
    @Route(.push) var serverDetail = makeServerDetail

    @ViewBuilder func makeServerDetail() -> some View {
        ServerDetailView()
    }

    @ViewBuilder func makeStart() -> some View {
        SettingsView(viewModel: .init())
    }
}
