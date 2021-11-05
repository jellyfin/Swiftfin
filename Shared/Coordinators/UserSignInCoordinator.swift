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

final class UserSignInCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \UserSignInCoordinator.start)

    @Root var start = makeStart

    let viewModel: UserSignInViewModel

    init(viewModel: UserSignInViewModel) {
        self.viewModel = viewModel
    }

    @ViewBuilder func makeStart() -> some View {
        UserSignInView(viewModel: viewModel)
    }
}
