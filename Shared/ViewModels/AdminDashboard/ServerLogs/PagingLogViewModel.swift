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
                .background(.loading)
            }
        }
    }

    enum BackgroundState {
        case loading
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
            self.refresh()
        }
    }

    let url: URL
    let pageSize: Int

    private let initialParser: Parser
    private var parser: Parser

    // Forward (ascending) — lazy byte streaming.
    private var handle: FileHandle?
    private var iterator: FileHandle.AsyncBytes.AsyncIterator?
    private var byteBuffer = Data()
    private var delimiterBytes = Data()

    // Reverse (descending) — eager parse, paginated from a reversed array.
    private var preparsedElements: [Parser.Element] = []
    private var preparsedCursor: Int = 0

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
        try open()
        try await loadPage()
    }

    @Function(\Action.Cases.getNextPage)
    private func _getNextPage() async throws {
        guard hasNextPage else { return }
        try open()
        try await loadPage()
    }

    private func reset() {
        try? handle?.close()
        handle = nil
        iterator = nil
        byteBuffer.removeAll()
        preparsedElements.removeAll()
        preparsedCursor = 0
        parser = initialParser
        elements = []
        hasNextPage = true
    }

    private func open() throws {
        switch direction {
        case .ascending:
            guard handle == nil else { return }
            let handle = try FileHandle(forReadingFrom: url)
            self.handle = handle
            self.iterator = handle.bytes.makeAsyncIterator()
            self.byteBuffer = Data()
            self.delimiterBytes = parser.delimiter.data(using: parser.encoding) ?? Data([0x0A])

        case .descending:
            // Read and parse the entire file up front, then paginate the reversed result.
            guard preparsedElements.isEmpty else { return }

            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: parser.encoding) else {
                hasNextPage = false
                return
            }

            for chunk in text.components(separatedBy: parser.delimiter) {
                preparsedElements.append(contentsOf: parser.consume(chunk: chunk))
            }
            preparsedElements.append(contentsOf: parser.flush())
            preparsedElements.reverse()
            preparsedCursor = 0
            hasNextPage = preparsedElements.isNotEmpty
        }
    }

    private func loadPage() async throws {
        switch direction {
        case .ascending:
            try await loadForwardPage()
        case .descending:
            loadReversePage()
        }
    }

    private func loadForwardPage() async throws {
        guard var iterator else {
            hasNextPage = false
            return
        }
        self.iterator = nil

        var newElements: [Parser.Element] = []
        var reachedEnd = false

        outer: while newElements.count < pageSize {
            if let range = byteBuffer.range(of: delimiterBytes) {
                let chunkData = byteBuffer.subdata(in: 0 ..< range.lowerBound)
                byteBuffer.removeSubrange(0 ..< range.upperBound)
                if let chunk = String(data: chunkData, encoding: parser.encoding) {
                    newElements.append(contentsOf: parser.consume(chunk: chunk))
                }
                continue
            }

            let target = byteBuffer.count + 4096
            while byteBuffer.count < target {
                guard let byte = try await iterator.next() else {
                    reachedEnd = true
                    break outer
                }
                byteBuffer.append(byte)
            }
        }

        if reachedEnd {
            if !byteBuffer.isEmpty,
               let chunk = String(data: byteBuffer, encoding: parser.encoding)
            {
                newElements.append(contentsOf: parser.consume(chunk: chunk))
            }
            byteBuffer.removeAll()
            newElements.append(contentsOf: parser.flush())
            try? handle?.close()
            handle = nil
            self.iterator = nil
            hasNextPage = false
        } else {
            self.iterator = iterator
        }

        if newElements.isNotEmpty {
            elements.append(contentsOf: newElements)
        }
    }

    private func loadReversePage() {
        let end = min(preparsedCursor + pageSize, preparsedElements.count)
        guard preparsedCursor < end else {
            hasNextPage = false
            return
        }
        elements.append(contentsOf: preparsedElements[preparsedCursor ..< end])
        preparsedCursor = end
        if preparsedCursor >= preparsedElements.count {
            hasNextPage = false
        }
    }
}
