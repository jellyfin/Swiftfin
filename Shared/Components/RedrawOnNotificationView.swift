//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct RedrawOnNotificationView<Content: View>: View {

    @State
    private var id = 0

    private let name: NSNotification.Name
    private let content: () -> Content

    init(name: NSNotification.Name, @ViewBuilder content: @escaping () -> Content) {
        self.name = name
        self.content = content
    }

    init(_ swiftfinNotification: Notifications.Key, @ViewBuilder content: @escaping () -> Content) {
        self.name = swiftfinNotification.underlyingNotification.name
        self.content = content
    }

    var body: some View {
        content()
            .id(id)
            .onNotification(name) { _ in
                id += 1
            }
    }
}
