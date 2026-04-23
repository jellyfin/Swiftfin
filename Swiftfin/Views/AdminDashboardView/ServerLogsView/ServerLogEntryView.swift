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
                if let level = entry.level {
                    LabeledContent(
                        L10n.level,
                        value: level.displayTitle
                    )
                }
                if let source = entry.source {
                    LabeledContent(
                        L10n.source,
                        value: source
                    )
                }
                if let timestamp = entry.timestamp {
                    LabeledContent(
                        L10n.date,
                        value: timestamp.formatted(date: .long, time: .shortened)
                    )
                }
            }

            Section(L10n.details) {
                StateAdapter(initialValue: false) { showCopiedAlert in
                    Button {
                        UIPasteboard.general.string = entry.message
                        showCopiedAlert.wrappedValue = true
                    } label: {
                        Text(entry.message)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundStyle(.primary, .secondary)
                    .alert(L10n.copiedToClipboard, isPresented: showCopiedAlert) {
                        Button(L10n.ok, role: .cancel) {}
                    } message: {
                        Text(L10n.copiedToClipboardMessage)
                    }
                }
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.details)
    }
}
