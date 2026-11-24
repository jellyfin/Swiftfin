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
import SwiftUI

@MainActor
final class MediaSegmentObserver {

    typealias Loader = @MainActor (String, UserSession) async throws -> [MediaSegmentDto]

    private struct ActiveSegment {

        let id = UUID()
        let segment: MediaSegment
        let action: MediaSegmentAction
        var remainingDelay: TimeInterval
        var deadline: Date?
    }

    private let configuration = Defaults[.VideoPlayer.mediaSegments]
    private let store: VideoPlayerOverlayActionStore
    private weak var item: MediaPlayerItem?
    private var observations: Set<AnyCancellable> = []
    private var activeSegment: ActiveSegment?
    private var publishedButton: (id: UUID, deadline: Date?)?
    private var requestedSkip: (target: Duration, active: ActiveSegment)?
    private var pendingSkip: (id: UUID, active: ActiveSegment)?

    init?(item: MediaPlayerItem, load: @escaping Loader = { itemID, session in
        try await session.send(Paths.getItemSegments(itemID: itemID)).value.items ?? []
    }) {
        guard let mediaSession = item.mediaSession,
              !item.baseItem.isLiveStream,
              item.baseItem.mediaType == .video,
              configuration.actions.values.contains(where: { $0 != .off }),
              let itemID = item.baseItem.id else { return nil }

        self.item = item
        self.store = item.overlayActions

        mediaSession.playbackEvents
            .sink { [weak self] event in
                self?.receive(event)
            }
            .store(in: &observations)

        let userSession = mediaSession.userSession

        Task { [weak self] in
            guard !Task.isCancelled, let history = self?.store.segmentHistory else { return }

            if !history.isLoaded {
                do {
                    let values = try await load(itemID, userSession)
                    guard !Task.isCancelled, let item = self?.item, item.mediaSession?.playbackItem === item else { return }

                    history.load(values)
                } catch {
                    if !Task.isCancelled {
                        self?.item?.mediaSession?.logger.debug("Media segments unavailable: \(error.localizedDescription)")
                    }
                    return
                }
            }

            let states = ObservableValues { [weak self] in
                (self?.playbackSession?.canSeek == true, self?.isPlaying == true)
            }

            for await _ in states {
                guard !Task.isCancelled else { return }

                self?.update()
            }
        }
        .store(in: &observations)
    }

    isolated deinit {
        endVisit()
    }

    private var isPlaying: Bool {
        guard let session = item?.mediaSession else { return false }

        return session.playbackRequestStatus == .playing && session.playbackState.isPlaying && session.activity == nil
    }

    private var playbackSession: MediaSession? {
        guard let mediaSession = item?.mediaSession,
              mediaSession.state == .playback,
              mediaSession.canControlPlayback,
              !mediaSession.isSeeking else { return nil }

        return mediaSession
    }

    private func receive(_ event: MediaSession.PlaybackEvent) {
        guard let item, item.mediaSession?.playbackItem === item else { return }

        switch event {
        case .positionChanged:
            update()
            // Confirm playback is still in this segment before acting on its deadline.
            if let activeSegment, let deadline = activeSegment.deadline, deadline <= .now {
                perform(activeSegment.id)
            }

        case let .seekRequested(request, _):
            if let requestedSkip, requestedSkip.target == request.target {
                pendingSkip = (request.id, requestedSkip.active)
            } else {
                pendingSkip = nil
            }

            requestedSkip = nil
            endVisit()

        case let .seekCompleted(request, position, hasPendingSeek):
            if let pendingSkip, pendingSkip.id == request.id {
                self.pendingSkip = nil
                let active = pendingSkip.active

                if !hasPendingSeek, position != nil {
                    store.segmentHistory.consume(active.segment, repeatMode: configuration.repeatMode)

                    if active.action == .skip {
                        item.didSkipMediaSegment.send(active.segment.type)
                    }
                } else if active.action == .skip {
                    store.segmentHistory.consume(active.segment, repeatMode: .everyTime)
                }
            }

            update()
        }
    }

    private func update() {
        guard let session = playbackSession else {
            pauseCountdown()
            withdrawButton()
            return
        }

        let pending = store.segmentHistory.pendingSegment(at: session.seconds, duration: session.duration, for: configuration)

        if let activeSegment, activeSegment.segment.skipTarget(at: session.seconds, duration: session.duration) == nil {
            endVisit()
        }

        guard session.canSeek else {
            pauseCountdown()
            withdrawButton()
            return
        }

        if activeSegment == nil {
            guard let segment = pending else { return }

            activeSegment = ActiveSegment(
                segment: segment,
                action: configuration[segment.type],
                remainingDelay: TimeInterval(configuration.skipDelay)
            )
        }

        if let activeSegment, activeSegment.action == .skip {
            if configuration.skipDelay == 0 {
                if isPlaying {
                    perform(activeSegment.id)
                }
                return
            } else if !isPlaying {
                pauseCountdown()
            } else if activeSegment.deadline == nil {
                self.activeSegment?.deadline = .now.addingTimeInterval(activeSegment.remainingDelay)
            }
        }

        if let activeSegment, publishedButton?.id != activeSegment.id || publishedButton?.deadline != activeSegment.deadline {
            publishButton(for: activeSegment)
        }
    }

    private func pauseCountdown() {
        guard let deadline = activeSegment?.deadline else { return }

        activeSegment?.remainingDelay = max(deadline.timeIntervalSinceNow, 0)
        activeSegment?.deadline = nil
    }

    private func endVisit() {
        withdrawButton()
        activeSegment = nil
    }

    private func withdrawButton() {
        guard let publishedButton else { return }

        self.publishedButton = nil
        store.withdraw(publishedButton.id)
    }

    private func keep(_ id: UUID) {
        guard let activeSegment, activeSegment.id == id else { return }

        store.segmentHistory.consume(activeSegment.segment, repeatMode: configuration.repeatMode)
        endVisit()
        update()
    }

    private func perform(_ id: UUID) {
        guard let session = playbackSession,
              let activeSegment,
              activeSegment.id == id,
              let target = activeSegment.segment.skipTarget(at: session.seconds, duration: session.duration) else { return }

        requestedSkip = (target, activeSegment)
        session.seek(to: target)
        requestedSkip = nil
    }

    private func publishButton(for active: ActiveSegment) {

        let id = active.id
        let keep: @MainActor () -> Void = { [weak self] in self?.keep(id) }
        let perform: @MainActor () -> Void = { [weak self] in self?.perform(id) }

        publishedButton = (id, active.deadline)

        store.publish(.init(id: id, action: active.action == .skip ? keep : perform, onDismiss: keep) {
            if active.action == .ask {
                Label(L10n.skip, systemImage: "forward.end.fill")
            } else {
                MediaSegmentCountdownLabel(
                    duration: TimeInterval(configuration.skipDelay),
                    deadline: active.deadline,
                    remaining: active.remainingDelay
                )
            }
        })
    }
}
