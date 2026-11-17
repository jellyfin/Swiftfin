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

    func dismissOverlayAction(_ id: String)
}

@MainActor
struct VideoPlayerOverlayAction: Identifiable {

    struct Countdown {

        let duration: TimeInterval
        let deadline: Date?
        let remaining: TimeInterval
    }

    let id: String
    let title: String
    let systemImage: String?
    let countdown: Countdown?
    let action: @MainActor () -> Void

    init(
        id: String,
        title: String,
        systemImage: String? = nil,
        countdown: Countdown? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.countdown = countdown
        self.action = action
    }
}
