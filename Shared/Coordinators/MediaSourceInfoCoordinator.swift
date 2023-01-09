//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

final class MediaSourceInfoCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \MediaSourceInfoCoordinator.start)

    @Root
    var start = makeStart
    @Route(.push)
    var mediaStreamInfo = makeMediaStreamInfo

    private let mediaSourceInfo: MediaSourceInfo

    init(mediaSourceInfo: MediaSourceInfo) {
        self.mediaSourceInfo = mediaSourceInfo
    }

    @ViewBuilder
    func makeMediaStreamInfo(mediaStream: MediaStream) -> some View {
        MediaStreamInfoView(mediaStream: mediaStream)
    }

    @ViewBuilder
    func makeStart() -> some View {
        ItemView.MediaSourceInfoView(mediaSource: mediaSourceInfo)
    }
}
