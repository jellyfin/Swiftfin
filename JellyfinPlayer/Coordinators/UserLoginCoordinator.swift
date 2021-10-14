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

final class UserLoginCoordinator: NavigationCoordinatable {
    let stack = NavigationStack(initial: \UserLoginCoordinator.start)
    
    @Root var start = makeStart
    
    let viewModel: UserLoginViewModel
    
    init(viewModel: UserLoginViewModel) {
        self.viewModel = viewModel
    }
    
    @ViewBuilder func makeStart() -> some View {
        UserLoginView(viewModel: viewModel)
    }
}
