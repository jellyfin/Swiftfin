//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import OrderedCollections
import SwiftUI

@MainActor
@Stateful
final class ServerLogsViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh
        case download(LogFile, force: Bool)

        var transition: Transition {
            switch self {
            case .refresh:
                .loop(.refreshing)
            case .download:
                .background(.downloading)
            }
        }
    }

    enum BackgroundState {
        case downloading
    }

    enum State {
        case initial
        case error
        case refreshing
    }

    @Published
    private(set) var logs: [LogFile] = []
    @Published
    private(set) var downloads: [LogFile: ServerLogDownload] = [:]

    @Published
    var filter: ServerLogType? {
        didSet { applyFilter() }
    }

    private var allLogs: OrderedSet<LogFile> = []

    private func applyFilter() {
        guard let filter else {
            logs = Array(allLogs)
            return
        }
        logs = allLogs.filter { $0.type == filter }
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let request = Paths.getServerLogs
        let response = try await userSession.client.send(request)
        allLogs = OrderedSet(response.value)
        applyFilter()
    }

    @Function(\Action.Cases.download)
    private func _download(_ log: LogFile, _ force: Bool) async throws {
        guard let name = log.name else {
            throw ErrorMessage(L10n.unknownError)
        }

        // Check if this file has already been downloaded before attempting to downloading
        if let existing = downloads[log], !force, FileManager.default.fileExists(atPath: existing.url.path) {
            return
        }

        let request = Paths.getLogFile(name: name)
        let response = try await userSession.client.download(for: request)

        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(name)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.moveItem(at: response.value, to: destination)

        let content = await ServerLogContent.load(
            from: destination,
            parseEntries: log.type == .system
        )

        // We JUST downloaded from this URL so this should always exist if the download was successful
        guard let webURL = userSession.client.fullURL(with: request, queryAPIKey: true) else { return }

        downloads[log] = ServerLogDownload(
            url: destination,
            webURL: webURL,
            content: content
        )
    }
}
