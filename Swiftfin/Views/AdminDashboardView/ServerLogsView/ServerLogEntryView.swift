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

    private var isProgressEntry: Bool {
        entry.source?.hasPrefix("FFmpeg Progress") == true
    }

    private var isStreamMappingEntry: Bool {
        entry.source == "Stream Mapping"
    }

    var body: some View {
        List {
            overviewSection

            if isProgressEntry {
                progressSections
            } else if isStreamMappingEntry {
                streamMappingSection
            } else if isFFmpegEntry {
                ffmpegFieldsSection
            } else {
                Section(L10n.details) {
                    Text(entry.message)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            rawSection
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.details)
    }

    @ViewBuilder
    private var overviewSection: some View {
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
    }

    @ViewBuilder
    private var ffmpegFieldsSection: some View {
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
    private var progressSections: some View {
        let lines = entry.message.components(separatedBy: "\n")
        let frameLine = lines.first ?? ""
        let events = lines.dropFirst()
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let stats = parseProgressStats(frameLine)

        if !events.isEmpty {
            Section(L10n.details) {
                ForEach(Array(events.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(.subheadline, design: .monospaced))
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
        }

        if !stats.isEmpty {
            Section("Progress") {
                ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                    LabeledContent(stat.key, value: stat.value)
                }
            }
        }
    }

    @ViewBuilder
    private var streamMappingSection: some View {
        let mappings = parseStreamMappings(entry.message)
        if !mappings.isEmpty {
            Section(L10n.details) {
                ForEach(Array(mappings.enumerated()), id: \.offset) { _, mapping in
                    LabeledContent("#\(mapping.source) → #\(mapping.dest)", value: mapping.description)
                }
            }
        }
    }

    @ViewBuilder
    private var rawSection: some View {
        Section {
            DisclosureGroup("Raw") {
                Text(entry.message)
                    .font(.system(.subheadline, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
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

    private var parsedFields: [(key: String, value: String)] {
        entry.message
            .split(separator: "\n", omittingEmptySubsequences: false)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty,
                      let separator = trimmed.range(of: ": ")
                else { return nil }
                let key = String(trimmed[..<separator.lowerBound])
                    .trimmingCharacters(in: .whitespaces)
                let value = String(trimmed[separator.upperBound...])
                    .trimmingCharacters(in: .whitespaces)
                return (key, value)
            }
    }

    private func parseProgressStats(_ line: String) -> [(key: String, value: String)] {
        let pattern = /(\w+)=\s*(\S+)/
        return line.matches(of: pattern).map { match in
            (String(match.output.1), String(match.output.2))
        }
    }

    private func parseStreamMappings(
        _ message: String
    ) -> [(source: String, dest: String, description: String)] {
        let pattern = /^\s*Stream\s+#([\d:]+)\s*->\s*#([\d:]+)\s*\((.+)\)\s*$/
        return message
            .split(separator: "\n", omittingEmptySubsequences: false)
            .compactMap { line in
                guard let match = try? pattern.wholeMatch(in: line) else { return nil }
                return (
                    String(match.output.1),
                    String(match.output.2),
                    String(match.output.3)
                )
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
