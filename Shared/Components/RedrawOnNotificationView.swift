//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct RedrawOnNotificationView<Content: View, P>: View {

    @State
    private var id = 0

    private let filter: (P) -> Bool
    private let key: Notifications.Key<P>
    private let content: Content

    init(
        _ key: Notifications.Key<P>,
        filter: @escaping (P) -> Bool = { _ in true },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.filter = filter
        self.key = key
        self.content = content()
    }

    var body: some View {
        content
            .id(id)
            .onNotification(key) { p in
                guard filter(p) else { return }
                id += 1
            }
    }
}
