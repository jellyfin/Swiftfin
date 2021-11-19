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

final class LiveTVChannelsCoordinator: NavigationCoordinatable {
    let stack = NavigationStack(initial: \LiveTVChannelsCoordinator.start)

    @Root var start = makeStart
    @Route(.modal) var modalItem = makeModalItem
    @Route(.fullScreen) var videoPlayer = makeVideoPlayer
    
    func makeModalItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
        return NavigationViewCoordinator(ItemCoordinator(item: item))
    }
    func makeVideoPlayer(item: BaseItemDto) -> NavigationViewCoordinator<VideoPlayerCoordinator> {
        NavigationViewCoordinator(VideoPlayerCoordinator(item: item))
    }
    
    @ViewBuilder
    func makeStart() -> some View {
        LiveTVChannelsView()
    }
}
