//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class VideoPlayerCoordinator: NavigationCoordinatable {
    var navigationStack = NavigationStack()
    var item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
    }

    enum Route: NavigationRoute {}

    func resolveRoute(route: Route) -> Transition {}

    @ViewBuilder
    func start() -> some View {
        VideoPlayerView(item: item)
    }
}
