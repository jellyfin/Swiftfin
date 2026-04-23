//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ServerLogDetailsView {

    struct ParsedServerLogRow: View {

        let entry: ServerLogEntry

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: entry.level?.systemImage ?? "questionmark.circle")
                        .foregroundStyle(entry.level?.color ?? .gray)

                    Text(entry.source ?? L10n.unknown)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.headline)

                Text(entry.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Group {
                    if let timestamp = entry.timestamp {
                        Text(timestamp.formatted(date: .abbreviated, time: .standard))
                    } else {
                        Text(String.emptyRuntime)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
    }
}
