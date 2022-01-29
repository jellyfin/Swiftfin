//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class OfflineHomeCoordinator: NavigationCoordinatable {
 
    let stack = NavigationStack(initial: \OfflineHomeCoordinator.start)
    
    @Root
    var start = makeStart
    @Route(.push)
    var item = makeItem
    @Route(.modal)
    var settings = makeSettings
    
    func makeItem(offlineItem: OfflineItem) -> NavigationViewCoordinator<OfflineItemCoordinator> {
        NavigationViewCoordinator(OfflineItemCoordinator(offlineItem: offlineItem))
    }
    
    func makeSettings() -> NavigationViewCoordinator<OfflineSettingsCoordinator> {
        NavigationViewCoordinator(OfflineSettingsCoordinator())
    }
    
    @ViewBuilder
    func makeStart() -> some View {
        OfflineHomeView(viewModel: OfflineHomeViewModel())
    }
}
