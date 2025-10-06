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

// TODO: feature implementations
//       - PiP
// TODO: Chromecast proxy

/// The proxy for top-down communication to an
/// underlying media player
protocol MediaPlayerProxy: ObservableObject, MediaPlayerObserver {

    var isBuffering: PublishedBox<Bool> { get }

    func play()
    func pause()
    func stop()

    func jumpForward(_ seconds: Duration)
    func jumpBackward(_ seconds: Duration)
    func setRate(_ rate: Float)
    func setSeconds(_ seconds: Duration)
}

@MainActor
protocol VideoMediaPlayerProxy: MediaPlayerProxy {

    associatedtype VideoPlayerBody: View

    var videoSize: PublishedBox<CGSize> { get }

    // TODO: remove when container view handles aspect fill
    func setAspectFill(_ aspectFill: Bool)
    func setAudioStream(_ stream: MediaStream)
    func setSubtitleStream(_ stream: MediaStream)

    @ViewBuilder
    @MainActor
    var videoPlayerBody: Self.VideoPlayerBody { get }
}

protocol MediaPlayerOffsetConfigurable {
    func setAudioOffset(_ seconds: Duration)
    func setSubtitleOffset(_ seconds: Duration)
}

protocol MediaPlayerSubtitleConfigurable {
    func setSubtitleColor(_ color: Color)
    func setSubtitleFontName(_ fontName: String)
    func setSubtitleFontSize(_ fontSize: Int)
}
