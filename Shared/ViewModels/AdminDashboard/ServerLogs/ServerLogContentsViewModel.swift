//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

@MainActor
@Stateful
final class ServerLogContentsViewModel: ViewModel {

    @CasePathable
    enum Action {
        case download(force: Bool)

        var transition: Transition {
            .background(.downloading)
        }
    }

    enum BackgroundState {
        case downloading
    }

    enum State {
        case initial
        case error
        case ready
    }

    @Published
    private(set) var url: URL?
    @Published
    private(set) var raw: PagingFileReader<RawLineParser>?
    @Published
    private(set) var parsed: PagingFileReader<ServerLogParser>?

    let log: LogFile

    var parses: Bool {
        log.type == .system
    }

    var webURL: URL? {
        guard let name = log.name else { return nil }
        return userSession.client.fullURL(with: Paths.getLogFile(name: name), queryAPIKey: true)
    }

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
            return
        }

        let request = Paths.getLogFile(name: name)
        let response = try await userSession.client.download(for: request)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: response.value, to: destination)

        setURL(destination)
    }

    private func setURL(_ url: URL) {
        self.url = url

        let raw = PagingFileReader(url: url, parser: RawLineParser())
        self.raw = raw
        raw.start()

        if parses {
            let parsed = PagingFileReader(url: url, parser: ServerLogParser())
            self.parsed = parsed
            parsed.start()
        } else {
            self.parsed = nil
        }
    }
}
