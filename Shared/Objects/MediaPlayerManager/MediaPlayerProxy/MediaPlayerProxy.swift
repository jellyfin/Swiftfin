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
protocol MediaPlayerProxy: ObservableObject {

    associatedtype VideoPlayerBody: View = EmptyView

    func play()
    func pause()
    func jumpForward(_ seconds: Duration)
    func jumpBackward(_ seconds: Duration)
    func setRate(_ rate: Float)
    func setSeconds(_ seconds: Duration)
    func setAudioStream(_ stream: MediaStream)
    func setSubtitleStream(_ stream: MediaStream)
    func setAspectFill(_ aspectFill: Bool)
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

class AnyMediaPlayerProxy: MediaPlayerProxy {

    let proxy: any MediaPlayerProxy

    init(_ proxy: any MediaPlayerProxy) {
        self.proxy = proxy
    }

    func play() {
        proxy.play()
    }

    func pause() {
        proxy.pause()
    }

    func jumpForward(_ seconds: Duration) {
        proxy.jumpForward(seconds)
    }

    func jumpBackward(_ seconds: Duration) {
        proxy.jumpBackward(seconds)
    }

    func setRate(_ rate: Float) {
        proxy.setRate(rate)
    }

    func setSeconds(_ seconds: Duration) {
        proxy.setSeconds(seconds)
    }

    func setAudioStream(_ stream: JellyfinAPI.MediaStream) {
        proxy.setAudioStream(stream)
    }

    func setSubtitleStream(_ stream: JellyfinAPI.MediaStream) {
        proxy.setSubtitleStream(stream)
    }

    func setAspectFill(_ aspectFill: Bool) {
        proxy.setAspectFill(aspectFill)
    }

    func stop() {
        proxy.stop()
    }

    func makeVideoPlayerBody(manager: MediaPlayerManager) -> AnyView? {
        AnyView(proxy.makeVideoPlayerBody(manager: manager))
    }
}
