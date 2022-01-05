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

final class LiveTVProgramsCoordinator: NavigationCoordinatable {
    
    let stack = NavigationStack(initial: \LiveTVProgramsCoordinator.start)

    @Root var start = makeStart
    @Route(.fullScreen) var videoPlayer = makeVideoPlayer
    
    func makeVideoPlayer(item: BaseItemDto) -> NavigationViewCoordinator<EmptyViewCoordinator> {
//        NavigationViewCoordinator(VideoPlayerCoordinator(item: item))
        NavigationViewCoordinator(EmptyViewCoordinator())
    }
    
    @ViewBuilder
    func makeStart() -> some View {
        LiveTVProgramsView()
    }
}
