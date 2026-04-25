//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ServerLogContentsView {

    struct ParsedServerEntry: View {

        let entry: ServerLogEntry
        let action: () -> Void

        var body: some View {
            ListRow {
                EmptyView()
            } content: {
                rowContent
                    .padding(.bottom, 8)
            }
            .onSelect(perform: action)
        }

        @ViewBuilder
        private var rowContent: some View {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: entry.type?.systemImage ?? "questionmark.circle")
                            .foregroundStyle(entry.type?.color ?? .gray)

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

                    if let timestamp = entry.timestamp {
                        Text(timestamp.formatted(date: .abbreviated, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .padding()
                    .font(.body.weight(.regular))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
