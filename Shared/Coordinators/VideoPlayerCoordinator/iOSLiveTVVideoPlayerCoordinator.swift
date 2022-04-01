//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class LiveTVVideoPlayerCoordinator: NavigationCoordinatable {
    
    let stack = NavigationStack(initial: \LiveTVVideoPlayerCoordinator.start)
    
    @Root
    var start = makeStart
    
    let viewModel: VideoPlayerViewModel
    
    init(viewModel: VideoPlayerViewModel) {
        self.viewModel = viewModel
    }
    
    @ViewBuilder
    func makeStart() -> some View {
//        if Defaults[.Experimental.liveTVNativePlayer] {
//            LiveTVNativeVideoPlayerView(viewModel: viewModel)
//                .navigationBarHidden(true)
//                .ignoresSafeArea()
//        } else {
            LiveTVPlayerView(viewModel: viewModel)
                .navigationBarHidden(true)
                .ignoresSafeArea()
//        }
    }
}
