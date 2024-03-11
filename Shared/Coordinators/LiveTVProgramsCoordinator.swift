//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Algorithms
import Defaults
import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class LiveTVProgramsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \LiveTVProgramsCoordinator.start)

    @Root
    var start = makeStart

    #if os(tvOS)
    @Route(.fullScreen)
    var videoPlayer = makeVideoPlayer
    #endif

    #if os(tvOS)
    func makeVideoPlayer(manager: VideoPlayerManager) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        BasicNavigationViewCoordinator {
            Group {
                if Defaults[.VideoPlayer.videoPlayerType] == .swiftfin {
                    VideoPlayer(manager: manager)
                        .overlay {
                            VideoPlayer.Overlay()
                        }
                } else {
                    NativeVideoPlayer(manager: manager)
                }
            }
        }
        .inNavigationViewCoordinator()
    }
    #endif

//    @ViewBuilder
    func makeStart() -> some View {
        let viewModel = LiveTVProgramsViewModel()

//        let channels = (1 ..< 20).map { _ in BaseItemDto.randomItem() }
//
//        for channel in channels {
//            viewModel.channels[channel.id!] = channel
//        }
//
//        viewModel.recommendedItems = channels.randomSample(count: 5)
//        viewModel.seriesItems = channels.randomSample(count: 5)
//        viewModel.movieItems = channels.randomSample(count: 5)
//        viewModel.sportsItems = channels.randomSample(count: 5)
//        viewModel.kidsItems = channels.randomSample(count: 5)
//        viewModel.newsItems = channels.randomSample(count: 5)

        return LiveTVProgramsView(viewModel: viewModel)
    }
}
