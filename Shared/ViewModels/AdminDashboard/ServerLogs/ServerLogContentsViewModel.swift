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
final class ServerLogContentsViewModel<Parser: LogParser>: ViewModel {

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
    private(set) var raw: PagingLogViewModel<RawLogParser>?
    @Published
    private(set) var parsed: PagingLogViewModel<Parser>?

    @Published
    var sortOrder: ItemSortOrder = .ascending {
        didSet {
            guard sortOrder != oldValue else { return }
            raw?.direction = sortOrder
            parsed?.direction = sortOrder
        }
    }

    @Published
    private(set) var url: URL? {
        didSet {
            guard let url, url != oldValue else { return }

            self.raw = PagingLogViewModel(url: url, parser: RawLogParser(), direction: sortOrder)
            self.raw?.start()

            if let parser {
                self.parsed = PagingLogViewModel(url: url, parser: parser, direction: sortOrder)
                self.parsed?.start()
            } else {
                self.parsed = nil
            }
        }
    }

    var webURL: URL? {
        guard let name = log.name else { return nil }
        return userSession.client.fullURL(with: Paths.getLogFile(name: name), queryAPIKey: true)
    }

    private let log: LogFile
    private let parser: Parser?

    init(log: LogFile, parser: Parser? = nil) {
        self.log = log
        self.parser = parser
        super.init()
    }

    @Function(\Action.Cases.download)
    private func _download(_ force: Bool) async throws {
        guard let name = log.name else {
            throw ErrorMessage(L10n.unknownError)
        }

        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(name)

        // Don't download unless forceable refreshed or the file doesn't exist yet
        if !force, FileManager.default.fileExists(atPath: destination.path) {
            self.url = destination
            return
        }

        let request = Paths.getLogFile(name: name)
        let response = try await userSession.client.download(for: request)

        // Remove the old file if this was this download is forced
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.moveItem(at: response.value, to: destination)

        self.url = destination
    }
}
