//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

class FlashContentProxy: ObservableObject {

    @Published
    var currentView: AnyView?
    @Published
    var isShowing = false

    private var dismissTimer: Timer?

    func flash<V: View>(interval: Double = 1, @ViewBuilder _ content: @escaping () -> V) {
        currentView = AnyView(content())
        isShowing = true
        restartOverlayDismissTimer(interval: interval)
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
        isShowing = false
        currentView = nil
    }
}
