//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ContentGroupSection<Header: View, Content: View>: View {

    private let content: Content
    private let header: Header

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Header
    ) {
        self.content = content()
        self.header = header()
    }

    private var spacing: CGFloat {
        UIDevice.isTV ? 30 : 15
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Section {
                content
            } header: {
                header
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
