//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
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

    private var dismissed: Set<String> = []
    private var suppressed: String?
    private var countdown: (segmentID: String, remaining: TimeInterval)?

    @ObservationIgnored
    private let configuration = Defaults[.VideoPlayer.mediaSegments]
    @ObservationIgnored
    private var request: AnyCancellable?
    @ObservationIgnored
    private var events: AnyCancellable?

    @ObservationIgnored
    private lazy var countdownTimer = DeadlineTimer { [weak self] in
        self?.countdown?.remaining = 0
        self?.updateCountdown()
    }

    init(load: @escaping Loader = { itemID, session in
        try await session.send(Paths.getItemSegments(itemID: itemID)).value.items ?? []
    }) {
        self.load = load
    }

    func observe(_ mediaSession: MediaSession) -> AnyCancellable {
        self.mediaSession = mediaSession
        item = mediaSession.playbackItem

        if let item,
           !item.baseItem.isLiveStream,
           item.baseItem.mediaType == .video,
           let type = item.baseItem.type,
           configuration.itemTypes.contains(type),
           let itemID = item.baseItem.id {
            let session = mediaSession.userSession

            request = Task { [weak self, weak item, load] in
                do {
                    let values = try await load(itemID, session)
                    guard !Task.isCancelled, let self, let item, self.mediaSession?.playbackItem === item else { return }

                    segments = MediaSegment.segments(from: values, itemID: itemID)
                } catch {
                    guard !Task.isCancelled else { return }

                    self?.mediaSession?.logger.debug("Media segments unavailable: \(error.localizedDescription)")
                }
            }
            .asAnyCancellable()

            events = mediaSession.playbackEvents.sink { [weak self] event in
                if case .seekRequested = event {
                    self?.stopCountdown()
                } else {
                    self?.updateCountdown()
                }
            }
        }

        let playback = ObservationToken { [weak self] in
            self?.isPlaying ?? false
        } onChange: { [weak self] _ in
            self?.updateCountdown()
        }

        return AnyCancellable { [self, playback] in
            MainActor.assumeIsolated {
                playback.cancel()
                request = nil
                events = nil
                segments = []
                dismissed = []
                suppressed = nil
                stopCountdown()
                self.mediaSession = nil
                item = nil
            }
        }
    }

    func dismissOverlayAction(_ id: String) {
        if configuration.repeatMode == .once {
            dismissed.insert(id)
        } else {
            suppressed = id
        }

        stopCountdown()
    }

    private var isPlaying: Bool {
        mediaSession?.playbackState.isPlaying == true && mediaSession?.activity == nil
    }

    private var skippableSession: MediaSession? {
        guard let mediaSession,
              let item,
              mediaSession.playbackItem === item,
              mediaSession.state == .playback,
              mediaSession.canSeek,
              !mediaSession.isSeeking else { return nil }

        return mediaSession
    }

    private func activeSegment(in mediaSession: MediaSession) -> (segment: MediaSegment, target: Duration)? {
        for segment in segments
            where configuration.action(for: segment) != .off && !dismissed.contains(segment.id) && suppressed != segment.id {
            if let target = segment.skipTarget(at: mediaSession.seconds, duration: mediaSession.duration) {
                return (segment, target)
            }
        }

        return nil
    }

    private func updateCountdown() {
        if let mediaSession,
           let segment = segments.first(where: { $0.id == suppressed }),
           segment.skipTarget(at: mediaSession.seconds, duration: mediaSession.duration) == nil {
            suppressed = nil
        }

        guard let mediaSession = skippableSession else {
            pauseCountdown()
            return
        }
        guard let active = activeSegment(in: mediaSession), configuration.action(for: active.segment) == .skip else {
            stopCountdown()
            return
        }

        if countdown?.segmentID != active.segment.id {
            stopCountdown()
            countdown = (active.segment.id, TimeInterval(configuration.skipDelay))
        }

        if let countdown, countdown.remaining <= 0 {
            skip(active, in: mediaSession)
        } else if !isPlaying {
            pauseCountdown()
        } else if let countdown, countdownTimer.deadline == nil {
            countdownTimer.start(until: .now.addingTimeInterval(countdown.remaining))
        }
    }

    private func pauseCountdown() {
        guard let deadline = countdownTimer.deadline else { return }

        countdown?.remaining = max(deadline.timeIntervalSinceNow, 0)
        countdownTimer.invalidate()
    }

    private func stopCountdown() {
        countdown = nil
        countdownTimer.invalidate()
    }

    private func skip(_ active: (segment: MediaSegment, target: Duration), in mediaSession: MediaSession) {
        if configuration.repeatMode == .once {
            dismissed.insert(active.segment.id)
        }

        stopCountdown()
        mediaSession.seek(to: active.target)
    }

    var overlayActions: [VideoPlayerOverlayAction] {
        guard let mediaSession = skippableSession,
              let segment = activeSegment(in: mediaSession)?.segment else { return [] }
        guard configuration.action(for: segment) == .ask else {
            guard let countdown, countdown.segmentID == segment.id else { return [] }

            return [VideoPlayerOverlayAction(
                id: segment.id,
                title: L10n.cancel,
                countdown: .init(
                    duration: TimeInterval(configuration.skipDelay),
                    deadline: countdownTimer.deadline,
                    remaining: countdown.remaining
                )
            ) { [weak self] in
                self?.dismissOverlayAction(segment.id)
            }]
        }

        return [VideoPlayerOverlayAction(
            id: segment.id,
            title: L10n.skip,
            systemImage: "forward.end.fill"
        ) { [weak self] in
            guard let mediaSession = self?.skippableSession,
                  let target = segment.skipTarget(at: mediaSession.seconds, duration: mediaSession.duration) else { return }

            mediaSession.seek(to: target)
        }]
    }
}
