//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import JellyfinAPI
import SwiftUI

struct ServerLogEntryView: View {

    let entry: ServerLogEntry

    var body: some View {
        List {
            Section(L10n.overview) {
                if let type = entry.type {
                    LabeledContent(L10n.level, value: type.displayTitle)
                }
                if let source = entry.source {
                    LabeledContent(L10n.source, value: source)
                }
                if let timestamp = entry.timestamp {
                    LabeledContent(
                        L10n.date,
                        value: timestamp.formatted(date: .long, time: .shortened)
                    )
                }
            }

            // Remove leading/trailing indentations.
            let message = entry.message
                .dropFirst()
                .trimmingCharacters(in: .whitespaces)

            if message.isNotEmpty {
                Section(L10n.details) {
                    Text(entry.message)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.details)
    }
}
