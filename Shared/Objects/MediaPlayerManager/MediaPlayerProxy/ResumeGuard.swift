//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Unpausing a live HLS playlist can re-sync playback to the live edge and skip
/// the viewer forward. Remembers where an in-progress recording was paused and
/// asks for a seek back if playback jumps ahead in the first seconds after resuming.
struct ResumeGuard {

    private var didPause = false
    private var target: Duration?
    private var until = Date.distantPast

    mutating func didPausePlayback() {
        didPause = true
    }

    mutating func willResumePlayback(isRecording: Bool, at seconds: Duration?) {
        if didPause, isRecording, let seconds {
            target = seconds
            until = .now + 15
        }

        didPause = false
    }

    mutating func disarm() {
        target = nil
    }

    /// The position to drag playback back to when the reported seconds jumped past the window
    mutating func correction(for seconds: Duration) -> Duration? {
        guard let target else { return nil }

        if Date.now > until {
            self.target = nil
            return nil
        }

        return seconds > target + .seconds(30) ? target : nil
    }
}
