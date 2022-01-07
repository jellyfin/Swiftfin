/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Defaults
import JellyfinAPI
import SwiftUI

struct LatestMediaView: View {
    
    @EnvironmentObject var homeRouter: HomeCoordinator.Router
    @StateObject var viewModel: LatestMediaViewModel
    @Default(.showPosterLabels) var showPosterLabels
    
    var body: some View {
        PortraitItemsRowView(rowTitle: L10n.latestWithString(viewModel.library.name ?? ""),
                             items: viewModel.items,
                             showItemTitles: showPosterLabels) { item in
            homeRouter.route(to: \.modalItem, item)
        }
    }
}
