//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
struct VideoPlayerOverlayAction: Identifiable {

    let id: UUID

    var focusID: String {
        "player.overlayAction.\(id)"
    }

    let label: AnyView
    let action: @MainActor () -> Void
    let onDismiss: @MainActor () -> Void

    init(
        id: UUID = UUID(),
        action: @escaping @MainActor () -> Void,
        onDismiss: @escaping @MainActor () -> Void = {},
        @ContentBuilder label: () -> some View
    ) {
        self.id = id
        self.label = AnyView(label())
        self.action = action
        self.onDismiss = onDismiss
    }
}
