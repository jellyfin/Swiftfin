//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@MainActor
struct VideoPlayerOverlayAction: Identifiable {

    let id: String
    let title: String
    let systemImage: String?
    let action: @MainActor () -> Void

    init(
        id: String,
        title: String,
        systemImage: String? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
}
