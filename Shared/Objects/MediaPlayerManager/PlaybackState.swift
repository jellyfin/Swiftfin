//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Observations from an engine, independent of what the user has requested.
struct PlaybackState: Equatable {

    var isReady = false
    var isPlaying = false
    var isSeekable = false
    var isSeeking = false
    var isWaitingForDisplay = false
    var duration: Duration?
    var isBuffering = false
}

/// Only one seek is dispatched at a time. Requests made while it runs replace
/// the queued target, but update the displayed position immediately.
struct PlaybackTimeline {

    struct Seek: Equatable {

        let id = UUID()
        let target: Duration
    }

    private(set) var observed: Duration = .zero
    private(set) var pending: Seek?
    private(set) var inFlight: Seek?

    var displayed: Duration {
        pending?.target ?? observed
    }

    mutating func observe(_ position: Duration) {
        observed = max(.zero, position)
    }

    mutating func requestSeek(to position: Duration, duration: Duration?) {
        let target = max(.zero, duration.map { min(position, $0) } ?? position)
        guard target != displayed else { return }

        pending = Seek(target: target)
    }

    mutating func beginSeek() -> Seek? {
        guard inFlight == nil, let pending else { return nil }

        inFlight = pending

        return pending
    }

    /// A completion for a previous load or request cannot clear a newer intent.
    @discardableResult
    mutating func completeSeek(_ id: UUID, position: Duration?) -> Bool {
        guard inFlight?.id == id else { return false }

        if let position {
            observe(position)
        }

        if pending?.id == id {
            pending = nil
        }

        inFlight = nil

        return true
    }

    mutating func reset(position: Duration = .zero) {
        self = PlaybackTimeline()
        observe(position)
    }
}
