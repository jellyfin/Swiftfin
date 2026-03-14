//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

class RepeatingTimer {

    let action: () -> Void
    private let interval: TimeInterval
    private var timer: Timer?

    init(interval: TimeInterval, _ action: @escaping () -> Void) {
        self.action = action
        self.interval = interval
    }

    @objc
    private func runAction() {
        action()
    }

    func start() {
        self.timer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(runAction),
            userInfo: nil,
            repeats: true
        )
    }

    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }
}
