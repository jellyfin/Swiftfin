//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LogEntryButton<LeadingContent: View>: View {

    private let title: String
    private let logLevel: LogLevel
    private let contents: String
    private let timestamp: Date?
    private let leadingContent: () -> LeadingContent
    private let action: () -> Void

    var body: some View {
        ChevronButton(action: action) {
            LabeledContent {
                rowContent
                    .frame(minHeight: 60)
            } label: {
                leadingContent()
                    .frame(width: 60, height: 60)
            }
        }
    }

    @ViewBuilder
    private var rowContent: some View {
        HStack {
            VStack(alignment: .leading) {

                // Header
                HStack(spacing: 4) {
                    Image(systemName: logLevel.systemImage)
                        .foregroundStyle(logLevel.color)

                    Text(title)
                        .foregroundStyle(.primary)
                        .truncationMode(.middle)
                }
                .font(.headline)

                // Contents
                Text(contents)
                    .font(.subheadline)

                // Timestamp
                Text(timestamp?.formatted(date: .abbreviated, time: .standard) ?? .emptyRuntime)
                    .font(.caption)

                // List row separator for usage in a CollectionVGrid.
                // Ensure that it goes all the way to the trailing edge of the screen.
                Divider()
                    .padding(.trailing, -(EdgeInsets.edgeInsets.trailing + EdgeInsets.edgePadding))
                    .frame(alignment: .bottom)
            }
            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .foregroundStyle(.secondary)
    }
}

extension LogEntryButton {

    init(
        title: String,
        logLevel: LogLevel,
        contents: String,
        timestamp: Date? = nil,
        action: @escaping () -> Void,
        @ViewBuilder leadingContent: @escaping () -> LeadingContent
    ) {
        self.title = title
        self.logLevel = logLevel
        self.contents = contents
        self.timestamp = timestamp
        self.leadingContent = leadingContent
        self.action = action
    }
}

extension LogEntryButton where LeadingContent == EmptyView {

    init(
        title: String,
        logLevel: LogLevel,
        contents: String,
        timestamp: Date? = nil,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            logLevel: logLevel,
            contents: contents,
            timestamp: timestamp,
            action: action,
            leadingContent: { EmptyView() }
        )
    }
}
