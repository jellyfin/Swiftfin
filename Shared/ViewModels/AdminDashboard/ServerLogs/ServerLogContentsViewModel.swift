//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import SwiftUI

@MainActor
@Stateful
final class ServerLogContentsViewModel<Parser: LogParser>: ViewModel {

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            .to(.initial, then: .content)
        }
    }

    enum State {
        case initial
        case error
        case content
    }

    @Published
    private(set) var logFile: LogFile
    @Published
    private(set) var rawLog: PagingLogViewModel<RawLogParser>?
    @Published
    private(set) var parsedLog: PagingLogViewModel<Parser>?

    @Published
    private(set) var downloadLocation: URL? {
        didSet {
            guard let downloadLocation, downloadLocation != oldValue else { return }

            self.rawLog = PagingLogViewModel(url: downloadLocation, parser: RawLogParser())
            self.rawLog?.refresh()

            if let parser {
                self.parsedLog = PagingLogViewModel(url: downloadLocation, parser: parser)
                self.parsedLog?.refresh()
            } else {
                self.parsedLog = nil
            }

            readerSubs.removeAll()

            rawLog?.objectWillChange
                .sink { [weak self] in self?.objectWillChange.send() }
                .store(in: &readerSubs)

            parsedLog?.objectWillChange
                .sink { [weak self] in self?.objectWillChange.send() }
                .store(in: &readerSubs)
        }
    }

    private var readerSubs = Set<AnyCancellable>()

    private let parser: Parser?

    init(logFile: LogFile, parser: Parser? = nil) {
        self.logFile = logFile
        self.parser = parser
        super.init()
    }

    // MARK: - Refresh

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        guard let name = logFile.name else {
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Paths.getLogFile(name: name)
        let response = try await userSession?.client.download(for: request)

        self.downloadLocation = response?.value

        await self.parsedLog?.refresh()
        await self.rawLog?.refresh()
    }
}
