//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Rename to something more generic, non-proxy

class TimerProxy: ObservableObject {

    @Published
    var isActive = false

    private var stopWorkitem: DispatchWorkItem?

    func start(_ interval: Double) {
        isActive = true
        restartOverlayDismissTimer(interval: interval)
    }

    func stop() {
        isActive = false
    }

    /// Stops the timer without triggering an active update
    func pause() {
        stopWorkitem?.cancel()
    }

    private func restartOverlayDismissTimer(interval: Double) {
        stopWorkitem?.cancel()

        isActive = true

        let newWorkItem = DispatchWorkItem {
            self.stop()
        }

        stopWorkitem = newWorkItem

        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: newWorkItem)
    }
}
