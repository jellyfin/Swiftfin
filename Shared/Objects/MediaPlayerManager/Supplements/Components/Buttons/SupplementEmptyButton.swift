//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SupplementEmptyButton: View {

    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(.complexSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .posterStyle(.landscape)
                .posterShadow()
                .hoverEffect(.highlight)
                .overlay {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.primary)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(String.random(count: 10 ..< 20))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1, reservesSpace: true)
                    .foregroundStyle(.primary)
                    .redacted(reason: .placeholder)

                DotHStack {
                    Text(String.random(count: 1 ..< 2))
                    Text(String.random(count: 2 ..< 3))
                }
                .redacted(reason: .placeholder)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
        }
    }
}
