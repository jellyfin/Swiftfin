//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

final class QuickConnectCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \QuickConnectCoordinator.start)

    @Root
    var start = makeStart

    private let viewModel: UserSignInViewModel

    init(viewModel: UserSignInViewModel) {
        self.viewModel = viewModel
    }

    @ViewBuilder
    func makeStart() -> some View {
        QuickConnectView(viewModel: viewModel)
    }
}
