//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

@MainActor
protocol VideoPlayerOverlayActionProviding {

    var id: String { get }
    var overlayActions: [VideoPlayerOverlayAction] { get }
}

@MainActor
struct VideoPlayerOverlayAction: Identifiable {

    struct Countdown {

        let interval: ClosedRange<Date>
        let pausedAt: Date?
    }

    let id: String
    let title: String
    let systemImage: String?
    let countdown: Countdown?
    let onDismiss: (@MainActor () -> Void)?
    let action: @MainActor () -> Void

    init(
        id: String,
        title: String,
        systemImage: String? = nil,
        countdown: Countdown? = nil,
        onDismiss: (@MainActor () -> Void)? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.countdown = countdown
        self.onDismiss = onDismiss
        self.action = action
    }
}
