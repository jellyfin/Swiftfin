//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct WithRouter<Content: View>: View {

    @Router
    private var router

    private let content: (Router.Wrapper) -> Content

    init(@ViewBuilder content: @escaping (Router.Wrapper) -> Content) {
        self.content = content
    }

    var body: some View {
        content(router)
    }
}
