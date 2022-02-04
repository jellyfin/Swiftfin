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

final class OfflineItemCoordinator: NavigationCoordinatable {
    
    let stack = NavigationStack(initial: \OfflineItemCoordinator.start)
    
    @Root
    var start = makeStart
    @Route(.fullScreen)
    var videoPlayer = makeVideoPlayer
    
    let offlineItem: OfflineItem
    
    init(offlineItem: OfflineItem) {
        self.offlineItem = offlineItem
    }
    
    func makeVideoPlayer(viewModel: VideoPlayerViewModel) -> NavigationViewCoordinator<VideoPlayerCoordinator> {
        NavigationViewCoordinator(VideoPlayerCoordinator(viewModel: viewModel))
    }
    
    @ViewBuilder
    func makeStart() -> some View {
        OfflineItemView(offlineItem: offlineItem)
            .navigationBarTitleDisplayMode(.inline)
    }
}
