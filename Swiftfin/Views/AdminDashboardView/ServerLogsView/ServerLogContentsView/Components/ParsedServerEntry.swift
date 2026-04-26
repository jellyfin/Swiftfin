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
            ChevronButton(action: action) {
                LabeledContent {
                    rowContent
                } label: {
                    EmptyView()
                }
            }
            .listRowSeparator()
        }

        @ViewBuilder
        private var rowContent: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: entry.type.systemImage)
                            .foregroundStyle(entry.type.color)

                        Text(entry.source ?? .emptyDash)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .font(.headline)

                    Text(entry.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.leading)

                    Text(entry.timestamp?.formatted(date: .abbreviated, time: .standard) ?? .emptyRuntime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
        }
    }
}
