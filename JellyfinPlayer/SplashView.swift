//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Stinsen
import SwiftUI

struct SplashView: View {
    @EnvironmentObject var mainRouter: MainCoordinator.Router
    @StateObject var viewModel = SplashViewModel()

    var body: some View {
        ProgressView()
            .onReceive(viewModel.$isLoggedIn) { flag in
                if flag {
                    mainRouter.root(\.mainTab)
                } else {
                    mainRouter.root(\.connectToServer)
                }
            }
    }
}
