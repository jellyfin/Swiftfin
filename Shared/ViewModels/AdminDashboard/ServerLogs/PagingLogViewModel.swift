//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import IdentifiedCollections

// TODO: Migrate over to new paging logic in https://github.com/jellyfin/Swiftfin/pull/1752

@MainActor
@Stateful
final class PagingLogViewModel<Parser: LogParser>: ViewModel {

    @CasePathable
    enum Action {
        case getNextPage
        case refresh

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.initial, then: .content)
            case .getNextPage:
                .background(.refreshing)
            }
        }
    }

    enum BackgroundState {
        case refreshing
    }

    enum State {
        case initial
        case error
        case content
    }

    @Published
    private(set) var elements: [Parser.Element] = []
    @Published
    private(set) var hasNextPage: Bool = true

    @Published
    var direction: ItemSortOrder {
        didSet {
            guard direction != oldValue else { return }

            elements = []
            cursor = 0
            hasNextPage = parsed.isNotEmpty

            getNextPage()
        }
    }

    let url: URL
    let pageSize: Int

    private let initialParser: Parser
    private var parser: Parser

    /// All elements parsed from the file.
    private var parsed: [Parser.Element] = []

    /// Number of elements already parsed.
    private var cursor: Int = 0

    init(
        url: URL,
        parser: Parser,
        pageSize: Int = 100,
        direction: ItemSortOrder = .ascending
    ) {
        self.url = url
        self.initialParser = parser
        self.parser = parser
        self.pageSize = pageSize
        self.direction = direction
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        reset()
        try openLog()
        try await loadPage()
    }

    @Function(\Action.Cases.getNextPage)
    private func _getNextPage() async throws {
        guard hasNextPage else { return }
        try openLog()
        try await loadPage()
    }

    private func reset() {
        parser = initialParser
        parsed.removeAll()
        elements = []
        cursor = 0
        hasNextPage = true
    }

    /// Reads and parses the entire file once. No-op on subsequent calls.
    private func openLog() throws {
        guard parsed.isEmpty else { return }
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: parser.encoding) else {
            hasNextPage = false
            return
        }
        for chunk in text.components(separatedBy: parser.delimiter) {
            parsed.append(contentsOf: parser.consume(chunk: chunk))
        }
        parsed.append(contentsOf: parser.flush())
        hasNextPage = parsed.isNotEmpty
    }

    private func loadPage() async throws {
        let total = parsed.count
        guard cursor < total else {
            hasNextPage = false
            return
        }
        let take = min(pageSize, total - cursor)
        let slice: [Parser.Element]
        switch direction {
        case .ascending:
            slice = Array(parsed[cursor ..< cursor + take])
        case .descending:
            let end = total - cursor
            slice = parsed[end - take ..< end].reversed()
        }
        elements.append(contentsOf: slice)
        cursor += take
        if cursor >= total {
            hasNextPage = false
        }
    }
}
