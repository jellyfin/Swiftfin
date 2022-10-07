//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

class TimerProxy: ObservableObject {
    
    @Published
    var isActive = false
    @Published
    var wasForceStopped = false
    
    private var dismissTimer: Timer?
    
    func start(_ interval: Double) {
        print("Started timer")
        isActive = true
        wasForceStopped = false
        restartOverlayDismissTimer(interval: interval)
    }
    
    func stop() {
        print("Force stopped timer")
        dismissTimer?.invalidate()
        wasForceStopped = true
    }
    
    private func restartOverlayDismissTimer(interval: Double) {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(dismissTimerFired),
            userInfo: nil,
            repeats: false
        )
    }
    
    @objc
    private func dismissTimerFired() {
        isActive = false
        wasForceStopped = false
    }
}
