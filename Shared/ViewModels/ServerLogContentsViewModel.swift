//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import IdentifiedCollections
import JellyfinAPI
import SwiftUI

@MainActor
@Stateful
final class ServerLogContentsViewModel: ViewModel {

    @CasePathable
    enum Action {
        case download(force: Bool)
        case loadNextPage
        case refresh

        var transition: Transition {
            switch self {
            case .download:
                .background(.downloading)
            case .loadNextPage:
                .background(.loadingPage)
            case .refresh:
                .loop(.refreshing)
            }
        }
    }

    enum BackgroundState {
        case downloading
        case loadingPage
    }

    enum State {
        case initial
        case error
        case refreshing
    }

    // Lines per read from the downloaded `LogFile`
    static let pageSize = 100

    @Published
    private(set) var url: URL?
    @Published
    private(set) var lines: [String] = []
    @Published
    private(set) var entries: IdentifiedArrayOf<ServerLogEntry> = []
    @Published
    private(set) var isFinished: Bool = false

    let log: LogFile

    var parses: Bool {
        log.type == .system
    }

    var webURL: URL? {
        guard let name = log.name else { return nil }
        return userSession.client.fullURL(with: Paths.getLogFile(name: name), queryAPIKey: true)
    }

    private var reader: ServerLogStreamReader?
    private var isLoadingPage = false
    private var parseState = ParseState()

    init(log: LogFile) {
        self.log = log
        super.init()
    }

    @Function(\Action.Cases.download)
    private func _download(_ force: Bool) async throws {
        guard let name = log.name else {
            throw ErrorMessage(L10n.unknownError)
        }

        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(name)

        if !force, FileManager.default.fileExists(atPath: destination.path) {
            setURL(destination)
            try await loadPage()
            return
        }

        let request = Paths.getLogFile(name: name)
        let response = try await userSession.client.download(for: request)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: response.value, to: destination)

        setURL(destination)
        try await loadPage()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        guard let url else { return }
        resetStream(url: url)
        try await loadPage()
    }

    @Function(\Action.Cases.loadNextPage)
    private func _loadNextPage() async throws {
        guard !isFinished, !isLoadingPage else { return }
        try await loadPage()
    }

    private func setURL(_ url: URL) {
        self.url = url
        resetStream(url: url)
    }

    private func resetStream(url: URL) {
        lines = []
        entries = []
        isFinished = false
        parseState = ParseState()
        reader = ServerLogStreamReader(url: url)
    }

    private func loadPage() async throws {
        guard let reader else { return }

        isLoadingPage = true
        defer { isLoadingPage = false }

        let page = try await reader.nextPage(maxLines: Self.pageSize)

        if !page.lines.isEmpty {
            lines.append(contentsOf: page.lines)
        }

        if parses {
            var newEntries: [ServerLogEntry] = []
            for line in page.lines {
                consume(line: line, into: &newEntries)
            }
            if page.isFinal {
                flushPending(into: &newEntries)
            }
            if !newEntries.isEmpty {
                entries.append(contentsOf: newEntries)
            }
        }

        if page.isFinal {
            isFinished = true
        }
    }
}

// MARK: - Parsing

extension ServerLogContentsViewModel {

    /// Parser continuation state — tracks the in-progress entry across page boundaries.
    private struct ParseState {
        var pending: ServerLogEntry?
        var nextID: Int = 0
    }

    /// Jellyfin system log header: `[2000-12-31 12:23:45.123 -06:00] [INF] [64] Source: message`.
    /// Non-matching lines attach to the previous entry (stack traces, exception bodies).
    private static let lineRegex: Regex = /^\[([^\]]+)\] \[([A-Z]+)\] \[[^\]]+\] ([^:]+?): (.*)$/

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS XXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private func consume(line: String, into entries: inout [ServerLogEntry]) {

        // Header lines always start with `[` — cheap prefix check before the regex.
        if line.first == "[", let match = try? Self.lineRegex.wholeMatch(in: line) {

            if let pending = parseState.pending {
                entries.append(pending)
            }

            parseState.pending = ServerLogEntry(
                id: parseState.nextID,
                timestamp: Self.timestampFormatter.date(from: String(match.output.1)),
                level: ServerLogEntry.Level(rawValue: String(match.output.2)),
                source: String(match.output.3),
                message: String(match.output.4)
            )
            parseState.nextID += 1

        } else if parseState.pending != nil {

            parseState.pending!.message.append("\n")
            parseState.pending!.message.append(line)

        } else if !line.isEmpty {

            // Orphan line before any header has been seen.
            entries.append(
                ServerLogEntry(
                    id: parseState.nextID,
                    timestamp: nil,
                    level: nil,
                    source: nil,
                    message: line
                )
            )
            parseState.nextID += 1
        }
    }

    private func flushPending(into entries: inout [ServerLogEntry]) {
        if let pending = parseState.pending {
            entries.append(pending)
            parseState.pending = nil
        }
    }
}
