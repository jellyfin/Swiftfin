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

    @ScaledMetric
    private var avatarSize: CGFloat = 60
    @ScaledMetric
    private var spacing: CGFloat = 4

    private let title: String
    private let logLevel: LogLevel
    private let contents: String
    private let timestamp: Date?
    private let leadingContent: () -> LeadingContent
    private let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ChevronButton(action: action) {
                LabeledContent {
                    AlternateLayoutView(alignment: .leading) {
                        rowContent
                    } content: {
                        rowContent
                    }
                    .layoutPriority(1)
                } label: {
                    leadingContent()
                        .frame(width: avatarSize, height: avatarSize, alignment: .center)
                }
            }
        }
    }

    @ViewBuilder
    private var rowContent: some View {
        VStack(alignment: .leading, spacing: spacing) {

            HStack(spacing: spacing) {
                Image(systemName: logLevel.systemImage)
                    .foregroundStyle(logLevel.color)

                Text(title)
                    .foregroundStyle(.primary)
                    .truncationMode(.middle)
            }
            .font(.headline)

            Text(contents)
                .font(.subheadline)

            Text(timestamp?.formatted(date: .abbreviated, time: .standard) ?? .emptyRuntime)
                .font(.caption)

            Divider()
                .padding(.trailing, -(EdgeInsets.edgePadding + EdgeInsets.edgeInsets.trailing))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
