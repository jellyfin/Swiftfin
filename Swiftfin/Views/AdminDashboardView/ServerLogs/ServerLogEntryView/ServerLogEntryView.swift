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
                LabeledContent(L10n.level, value: entry.type.displayTitle)

                if let source = entry.source {
                    if let dotIndex = source.lastIndex(of: ".") {
                        LabeledContent(L10n.source, value: String(source[..<dotIndex]))
                        LabeledContent(L10n.caller, value: String(source[source.index(after: dotIndex)...]))
                    } else {
                        LabeledContent(L10n.source, value: source)
                    }
                }

                if let timestamp = entry.timestamp {
                    LabeledContent(
                        L10n.date,
                        value: timestamp.formatted(date: .long, time: .shortened)
                    )
                }
            }

            if entry.message.isNotEmpty {
                Section(L10n.details) {
                    Text(entry.message)
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
