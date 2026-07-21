//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

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
    func setSeconds(_ seconds: Duration, completion: ((Bool) -> Void)?)
}

extension MediaPlayerProxy {

    /// Convenience for `setSeconds` without a completion action.
    func setSeconds(_ seconds: Duration) {
        setSeconds(seconds, completion: nil)
    }
}

@MainActor
protocol VideoMediaPlayerProxy: MediaPlayerProxy, MediaPlayerAudioTrackConfigurable, MediaPlayerSubtitleTrackConfigurable {

    associatedtype VideoPlayerBody: View

    var videoSize: PublishedBox<CGSize> { get }
    var droppedFrames: PublishedBox<Int> { get }
    var corruptedFrames: PublishedBox<Int> { get }

    // TODO: remove when container view handles aspect fill
    func setAspectFill(_ aspectFill: Bool)

    @ViewBuilder
    @MainActor
    var videoPlayerBody: Self.VideoPlayerBody { get }
}

@MainActor
protocol MediaPlayerAudioTrackConfigurable {
    func setAudioStream(_ stream: MediaStream)
}

@MainActor
protocol MediaPlayerSubtitleTrackConfigurable {
    func setSubtitleStream(_ stream: MediaStream)
}

@MainActor
protocol MediaPlayerOffsetConfigurable {
    func setAudioOffset(_ seconds: Duration)
    func setSubtitleOffset(_ seconds: Duration)
}

@MainActor
protocol MediaPlayerPictureInPictureCapable: AnyObject {
    var isPiPActive: PublishedBox<Bool> { get }
    var isPiPAvailable: PublishedBox<Bool> { get }
    func startPiP()
    func stopPiP()
}

@MainActor
protocol MediaPlayerSubtitleConfigurable {
    func setSubtitleColor(_ color: Color)
    func setSubtitleFontName(_ fontName: String)
    func setSubtitleFontSize(_ fontSize: Int)
}
