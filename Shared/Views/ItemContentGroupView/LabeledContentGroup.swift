//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LabeledContentGroup<Style: LabeledContentStyle>: ContentGroup {

    let displayTitle: String
    let id: String
    let style: Style
    let value: String

    init(
        _ title: String,
        value: String,
        style: Style
    ) {
        self.displayTitle = title
        self.id = UUID().uuidString
        self.style = style
        self.value = value
    }

    func body(with viewModel: Empty) -> some View {
        LabeledContent {
            Text(value)
        } label: {
            Text(displayTitle)
        }
        .labeledContentStyle(style)
        .edgePadding(.horizontal)
    }
}
