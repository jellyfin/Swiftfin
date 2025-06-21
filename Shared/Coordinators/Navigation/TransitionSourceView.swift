//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct TransitionSourceView<Content: View>: View {

    private let content: Content
    private let id: String
    private let namespace: Namespace.ID

    init(
        id: String,
        in namespace: Namespace.ID,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self.namespace = namespace
        self.content = content()
    }

    var body: some View {
        if #available(iOS 18.0, tvOS 18.0, *) {
            content
                .matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}
