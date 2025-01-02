//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LearnMoreModal: View {

    private let items: [TextPair]

    // MARK: - Initializer

    init(@ArrayBuilder<TextPair> items: () -> [TextPair]) {
        self.items = items()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(items) { content in
                VStack(alignment: .leading, spacing: 8) {
                    Text(content.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(content.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Material.regular)
        }
        .padding()
    }
}
