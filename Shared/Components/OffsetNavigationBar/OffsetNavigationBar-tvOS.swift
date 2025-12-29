//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OffsetNavigationBar<Content: View>: View {

    private let content: Content

    init(
        headerMaxY: CGFloat?,
        start: CGFloat = 25,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        content
    }
}
