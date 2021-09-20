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

final class ConnectToServerCoodinator: NavigationCoordinatable {
    let stack = NavigationStack(initial: \ConnectToServerCoodinator.start)

    @Root var start = makeStart
    
    @ViewBuilder func makeStart() -> some View {
        ConnectToServerView()
    }
}
