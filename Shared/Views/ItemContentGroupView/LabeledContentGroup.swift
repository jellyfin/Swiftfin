//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LabeledContentGroup: ContentGroup {

    let displayTitle: String
    let id: String
    let value: String

    init(
        _ title: String,
        value: String
    ) {
        self.displayTitle = title
        self.id = UUID().uuidString
        self.value = value
    }

    func body(with viewModel: Empty) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayTitle)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(value)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .edgePadding(.horizontal)
    }
}
