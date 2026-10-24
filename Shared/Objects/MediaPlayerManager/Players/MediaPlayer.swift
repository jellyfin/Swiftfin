//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Observation
import SwiftUI

// TODO: Maybe clean up Providing protocols

@MainActor
protocol MediaPlayer: AnyObject, Observable {

    var mediaSession: MediaSession? { get set }

    var displayTitle: String { get }
    var mediaPlayerType: MediaPlayerType { get }

    func load(_ item: MediaPlayerItem)

    func play()
    func pause()
    func stop()

    func setRate(_ rate: Double)
    func seek(_ request: PlaybackTimeline.Seek)
    func cancelSeek()
}

@MainActor
protocol VideoMediaPlayer: MediaPlayer, MediaPlayerTrackProviding {

    associatedtype VideoPlayerBody: View

    var videoState: VideoPlaybackState { get }

    @ViewBuilder
    @MainActor
    func videoPlayerBody(layout: VideoPlayer.VideoLayout) -> Self.VideoPlayerBody
}

@MainActor
protocol MediaPlayerTrackProviding {

    func setStream(_ stream: MediaStream)
}

@MainActor
protocol MediaPlayerMetadataProviding {

    func updateMetadata(for item: MediaPlayerItem, artwork: UIImage?)
}

@MainActor
protocol MediaPlayerOffsetProviding {

    func setOffset(_ seconds: Duration, for type: MediaStreamType)
}

@MainActor
protocol MediaPlayerSecondarySubtitleProviding {

    func setSecondarySubtitle(_ index: Int?)
    func setSecondarySubtitleOffset(_ seconds: Duration)
}

@MainActor
protocol MediaPlayerSubtitleCueProviding {

    var subtitleCues: Set<SubtitleCue> { get }

    func canObserveSubtitleCues(at playerIndex: Int) -> Bool
}

@MainActor
protocol MediaPlayerPictureInPictureProviding: AnyObject, Observable {

    var allowsAutomaticPiP: Bool { get set }
    var isPiPActive: Bool { get }
    var isPiPAvailable: Bool { get }
    var isPiPTransitioning: Bool { get }

    func startPiP()
    func stopPiP()
}
