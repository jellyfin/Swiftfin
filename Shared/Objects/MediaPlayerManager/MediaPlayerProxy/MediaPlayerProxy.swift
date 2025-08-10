//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

/// The proxy for top-down communication to an
/// underlying media player
protocol MediaPlayerProxy {

    associatedtype VideoPlayerBody: View = EmptyView

    func play()
    func pause()
    func jumpForward(_ seconds: Duration)
    func jumpBackward(_ seconds: Duration)
    func setRate(_ rate: Float)
    func setSeconds(_ seconds: Duration)
    func setAudioStream(_ stream: MediaStream)
    func setSubtitleStream(_ stream: MediaStream)

    func stop()

    @ViewBuilder
    @MainActor
    func makeVideoPlayerBody(manager: MediaPlayerManager) -> VideoPlayerBody
}

extension MediaPlayerProxy where VideoPlayerBody == EmptyView {
    func makeVideoPlayerBody(manager: MediaPlayerManager) -> VideoPlayerBody {
        EmptyView()
    }
}
