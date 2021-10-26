//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import SwiftUI

struct LiveTVGuideView: View {
    @EnvironmentObject var programsRouter: LiveTVGuideCoordinator.Router
    @StateObject var viewModel = LiveTVGuideViewModel()

    var body: some View {
        Button {} label: {
            Text("Coming Soon")
        }
    }
}
