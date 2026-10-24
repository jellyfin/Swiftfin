//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import Observation

@MainActor
@Observable
final class MediaSegmentObserver: MediaSessionObserver, VideoPlayerOverlayActionProviding {

    typealias Loader = @MainActor (String, UserSession) async throws -> [MediaSegmentDto]

    let id = "mediaSegments"
    private weak var item: MediaPlayerItem?
    private let load: Loader
    private weak var mediaSession: MediaSession?
    private(set) var segments: [MediaSegment] = []

    @ObservationIgnored
    private var request: AnyCancellable?

    init(load: @escaping Loader = { itemID, session in
        try await session.send(Paths.getItemSegments(itemID: itemID)).value.items ?? []
    }) {
        self.load = load
    }

    func observe(_ mediaSession: MediaSession) -> AnyCancellable {
        self.mediaSession = mediaSession
        item = mediaSession.playbackItem

        if let item, !item.baseItem.isLiveStream, item.baseItem.mediaType != .audio,
           let itemID = item.baseItem.id
        {
            let session = mediaSession.userSession

            request = Task { [weak self, weak item, load] in
                do {
                    let values = try await load(itemID, session)
                    guard !Task.isCancelled, let self, let item, self.mediaSession?.playbackItem === item else { return }

                    segments = MediaSegment.segments(from: values, itemID: itemID)
                } catch {
                    // Playback can continue when segments are unavailable or unsupported.
                    guard !Task.isCancelled else { return }

                    self?.mediaSession?.logger.debug("Media segments unavailable: \(error.localizedDescription)")
                }
            }
            .asAnyCancellable()
        }

        return AnyCancellable { [self] in
            MainActor.assumeIsolated {
                request = nil
                segments = []
                self.mediaSession = nil
                item = nil
            }
        }
    }

    var overlayActions: [VideoPlayerOverlayAction] {
        guard let mediaSession, let item, mediaSession.playbackItem === item,
              mediaSession.state == .playback, mediaSession.canSeek, !mediaSession.isSeeking else { return [] }

        let duration = mediaSession.playbackState.duration ?? mediaSession.item.runtime

        return segments.compactMap { segment in
            guard segment.skipTarget(at: mediaSession.seconds, duration: duration) != nil else { return nil }

            return VideoPlayerOverlayAction(id: segment.id, title: L10n.skip, systemImage: "forward.end.fill") { [
                weak self,
                weak item
            ] in
                guard let self, let mediaSession = self.mediaSession, let item, self.item === item,
                      mediaSession.playbackItem === item, mediaSession.state == .playback, mediaSession.canSeek, !mediaSession.isSeeking,
                      let target = segment.skipTarget(
                          at: mediaSession.seconds,
                          duration: mediaSession.playbackState.duration ?? mediaSession.item.runtime
                      ) else { return }

                mediaSession.seek(to: target)
            }
        }
    }
}
