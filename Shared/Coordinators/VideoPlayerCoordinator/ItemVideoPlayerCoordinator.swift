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

final class ItemVideoPlayerCoordinator: NavigationCoordinatable {
    
    struct Parameters {
        let item: BaseItemDto
        let mediaSource: MediaSourceInfo
    }
    
    @Default(.Experimental.nativePlayer)
    private var nativePlayer

    let stack = NavigationStack(initial: \ItemVideoPlayerCoordinator.start)

    @Root
    var start = makeStart

    let parameters: Parameters

    init(parameters: Parameters) {
        self.parameters = parameters
    }

    @ViewBuilder
    func makeStart() -> some View {
        if nativePlayer {
            NativeVideoPlayer(manager: .init(item: parameters.item, mediaSource: parameters.mediaSource))
        } else {
            ItemVideoPlayer(manager: .init(item: parameters.item, mediaSource: parameters.mediaSource))
        }
    }
}
