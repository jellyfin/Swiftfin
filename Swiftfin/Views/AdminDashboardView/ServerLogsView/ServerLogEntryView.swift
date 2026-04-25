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

    @Router
    private var router

    let entry: ServerLogEntry

    private var isFFmpegEntry: Bool {
        entry.source?.hasPrefix("FFmpeg ") == true
    }

    private var parsedFields: [(key: String, value: String)] {
        entry.message
            .split(separator: "\n", omittingEmptySubsequences: false)
            .compactMap { line -> (key: String, value: String)? in
                guard let separator = line.range(of: ": ") else { return nil }
                let key = String(line[..<separator.lowerBound])
                let value = String(line[separator.upperBound...])
                return (key, value)
            }
    }

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

            if isFFmpegEntry {
                detailsSection
            } else {
                Section(L10n.details) {
                    Text(entry.message)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.details)
    }

    @ViewBuilder
    private var detailsSection: some View {
        Section(L10n.details) {
            ForEach(Array(parsedFields.enumerated()), id: \.offset) { _, field in
                if field.key == "MediaStreams",
                   let streams = decodeMediaStreams(from: field.value), !streams.isEmpty
                {
                    mediaStreamsRows(streams)
                } else {
                    LabeledContent(field.key, value: field.value)
                }
            }
        }
    }

    @ViewBuilder
    private func mediaStreamsRows(_ streams: [MediaStream]) -> some View {
        ForEach(Array(streams.enumerated()), id: \.offset) { _, stream in
            Button {
                router.route(to: .mediaStreamInfo(mediaStream: stream))
            } label: {
                HStack {
                    Text(streamTitle(stream))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func decodeMediaStreams(from json: String) -> [MediaStream]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([MediaStream].self, from: data)
    }

    private func streamTitle(_ stream: MediaStream) -> String {
        stream.displayTitle
            ?? stream.title
            ?? stream.codec
            ?? L10n.unknown
    }
}
