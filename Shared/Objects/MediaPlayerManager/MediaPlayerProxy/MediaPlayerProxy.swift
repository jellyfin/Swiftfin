//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

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
    func setSeconds(_ seconds: Duration, completion: ((Bool) -> Void)?)
}

extension MediaPlayerProxy {

    /// Convenience for `setSeconds` without a completion action.
    func setSeconds(_ seconds: Duration) {
        setSeconds(seconds, completion: nil)
    }
}

@MainActor
protocol VideoMediaPlayerProxy: MediaPlayerProxy {

    associatedtype VideoPlayerBody: View

    var videoPlayerType: VideoPlayerType { get }
    var videoSize: PublishedBox<CGSize> { get }
    var droppedFrames: PublishedBox<Int> { get }
    var corruptedFrames: PublishedBox<Int> { get }

    // TODO: remove when container view handles aspect fill
    func setAspectFill(_ aspectFill: Bool)
    func setAudioStream(_ stream: MediaStream)
    func setSubtitleStream(_ stream: MediaStream)

    @ViewBuilder
    @MainActor
    var videoPlayerBody: Self.VideoPlayerBody { get }
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
protocol AirPlayable {
    var supportsAirPlay: Bool { get }
    var airPlayPlayerType: VideoPlayerType? { get }
}

@MainActor
protocol PictureInPictureable {
    var supportsPiP: Bool { get }
    var pipPlayerType: VideoPlayerType? { get }
}

@MainActor
protocol MediaPlayerSubtitleConfigurable {
    func setSubtitleColor(_ color: Color)
    func setSubtitleFontName(_ fontName: String)
    func setSubtitleFontSize(_ fontSize: Int)
}

struct MediaPlayerPlaybackInfo {
    var droppedFrames: Int?
    var observedBitrateKbps: Double?
    var indicatedBitrateKbps: Double?
    var bytesTransferred: Int64?
}

@MainActor
protocol MediaPlayerPlaybackInfoProvider: AnyObject {
    var playbackInfo: PublishedBox<MediaPlayerPlaybackInfo?> { get }
}
