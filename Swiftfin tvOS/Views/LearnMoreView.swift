//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LearnMoreView: View {

    private let title: String
    private let items: [TextPair]

    // MARK: - Initializer

    init(_ title: String, @ArrayBuilder<TextPair> items: () -> [TextPair]) {
        self.title = title
        self.items = items()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(items) { content in
                VStack(alignment: .leading, spacing: 16) {
                    Text(content.title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Text(content.subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.tertiary)
        )
        .padding()
    }
}
