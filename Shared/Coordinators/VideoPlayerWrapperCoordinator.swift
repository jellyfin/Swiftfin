//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

// TODO: add normal video player
// TODO: replace current instances of video player on other coordinators, if able

/// A coordinator used on tvOS to present video players due to differences in view controller presentation.
final class VideoPlayerWrapperCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \VideoPlayerWrapperCoordinator.start)

    @Root
    var start = makeStart

    @Route(.fullScreen)
    var liveVideoPlayer = makeLiveVideoPlayer

    private let content: () -> any View

    init(@ViewBuilder _ content: @escaping () -> any View) {
        self.content = content
    }

    func makeLiveVideoPlayer(manager: LiveVideoPlayerManager) -> NavigationViewCoordinator<LiveVideoPlayerCoordinator> {
        NavigationViewCoordinator(LiveVideoPlayerCoordinator(manager: manager))
    }

    @ViewBuilder
    private func makeStart() -> some View {
        content()
            .eraseToAnyView()
    }
}
