//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation

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
            self.refresh()
        }
    }

    let url: URL
    let pageSize: Int

    private let initialParser: Parser
    private let delimiterBytes: Data
    private let readChunkSize = 64 * 1024

    private var handle: FileHandle?

    // Forward (ascending): persistent parser, handle position advances toward EOF.
    private var forwardBuffer = Data()
    private var forwardCursor = 0
    private var forwardParser: Parser

    // Backward (descending): fresh parser per window, tail offset retreats toward 0.
    private var reverseTail: UInt64 = 0

    init(
        url: URL,
        parser: Parser,
        pageSize: Int = 100,
        direction: ItemSortOrder = .ascending
    ) {
        self.url = url
        self.initialParser = parser
        self.forwardParser = parser
        self.pageSize = pageSize
        self.direction = direction
        self.delimiterBytes = parser.delimiter.data(using: parser.encoding) ?? Data([0x0A])
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {

        self.elements = []

        try open()
        try await loadPage()
    }

    @Function(\Action.Cases.getNextPage)
    private func _getNextPage() async throws {
        guard hasNextPage else { return }
        if handle == nil {
            try open()
        }
        try await loadPage()
    }

    private func open() throws {
        try? handle?.close()
        let h = try FileHandle(forReadingFrom: url)
        let size = try h.seekToEnd()
        try h.seek(toOffset: 0)
        handle = h
        forwardBuffer = Data()
        forwardCursor = 0
        forwardParser = initialParser
        reverseTail = size
        elements = []
        hasNextPage = size > 0
    }

    private func loadPage() async throws {
        switch direction {
        case .ascending:
            try loadForwardPage()
        case .descending:
            try loadBackwardPage()
        }
    }

    // MARK: - Forward

    private func loadForwardPage() throws {
        guard let handle else {
            hasNextPage = false
            return
        }

        var newElements: [Parser.Element] = []

        while newElements.count < pageSize {
            while newElements.count < pageSize,
                  let range = forwardBuffer.range(
                      of: delimiterBytes,
                      in: forwardCursor ..< forwardBuffer.count
                  )
            {
                let lineData = forwardBuffer.subdata(in: forwardCursor ..< range.lowerBound)
                forwardCursor = range.upperBound
                if let line = String(data: lineData, encoding: forwardParser.encoding) {
                    newElements.append(contentsOf: forwardParser.read(chunk: line))
                }
            }

            if newElements.count >= pageSize { break }

            // Compact the buffer when most of it is consumed, to keep the search range bounded.
            if forwardCursor >= readChunkSize {
                forwardBuffer.removeSubrange(0 ..< forwardCursor)
                forwardCursor = 0
            }

            let chunk = try handle.read(upToCount: readChunkSize) ?? Data()

            if chunk.isEmpty {
                // EOF: emit any trailing partial line + parser's pending state.
                if forwardCursor < forwardBuffer.count,
                   let line = String(
                       data: forwardBuffer.subdata(in: forwardCursor ..< forwardBuffer.count),
                       encoding: forwardParser.encoding
                   )
                {
                    newElements.append(contentsOf: forwardParser.read(chunk: line))
                }
                forwardBuffer.removeAll()
                forwardCursor = 0
                newElements.append(contentsOf: forwardParser.flush())
                hasNextPage = false
                break
            }

            forwardBuffer.append(chunk)
        }

        if newElements.isNotEmpty {
            elements.append(contentsOf: newElements)
        }
    }

    // MARK: - Backward

    private func loadBackwardPage() throws {
        guard let handle else {
            hasNextPage = false
            return
        }

        var newElements: [Parser.Element] = []

        while newElements.count < pageSize {
            if reverseTail == 0 {
                hasNextPage = false
                break
            }

            // Extend a window backward in chunks until it contains a parser-recognized header.
            // Parse from that header forward with a fresh parser, append reversed, then move
            // `reverseTail` to the header's byte offset for the next window.
            var windowBytes = Data()
            var windowStart = reverseTail
            var headerOffset: Int?

            while headerOffset == nil {
                let toRead = min(UInt64(readChunkSize), windowStart)
                if toRead == 0 {
                    // Reached byte 0 with no header — parse from the start of the file.
                    headerOffset = 0
                    break
                }
                let newStart = windowStart - toRead
                try handle.seek(toOffset: newStart)
                let chunk = try handle.read(upToCount: Int(toRead)) ?? Data()
                windowBytes = chunk + windowBytes
                windowStart = newStart

                // Cursor for the first well-formed line: byte 0 if at file start,
                // otherwise the byte after the first delimiter (skipping the partial leading line).
                let cursor: Int
                if windowStart == 0 {
                    cursor = 0
                } else if let firstDelim = windowBytes.range(of: delimiterBytes) {
                    cursor = firstDelim.upperBound
                } else {
                    // No delimiter visible yet — extend further.
                    continue
                }

                headerOffset = firstHeaderOffset(in: windowBytes, startingAt: cursor)
            }

            guard let offset = headerOffset,
                  let text = String(
                      data: windowBytes.subdata(in: offset ..< windowBytes.count),
                      encoding: initialParser.encoding
                  )
            else {
                hasNextPage = false
                break
            }

            var localParser = initialParser
            var entries: [Parser.Element] = []
            for line in text.components(separatedBy: initialParser.delimiter) {
                entries.append(contentsOf: localParser.read(chunk: line))
            }
            entries.append(contentsOf: localParser.flush())
            newElements.append(contentsOf: entries.reversed())

            let newTail = windowStart + UInt64(offset)
            // Defensive: ensure backward progress, else we'd spin forever.
            if newTail >= reverseTail {
                hasNextPage = false
                break
            }
            reverseTail = newTail
        }

        if newElements.isNotEmpty {
            elements.append(contentsOf: newElements)
        }
    }

    /// Scans forward from `start` through `bytes`, returning the offset of the first line
    /// the parser recognizes as a header. Returns `nil` if no header is found.
    private func firstHeaderOffset(in bytes: Data, startingAt start: Int) -> Int? {
        var cursor = start
        while cursor < bytes.count {
            let nextDelim = bytes.range(of: delimiterBytes, in: cursor ..< bytes.count)
            let lineEnd = nextDelim?.lowerBound ?? bytes.count
            if let line = String(
                data: bytes.subdata(in: cursor ..< lineEnd),
                encoding: initialParser.encoding
            ),
                initialParser.isHeader(line: line)
            {
                return cursor
            }
            guard let advance = nextDelim?.upperBound else { return nil }
            cursor = advance
        }
        return nil
    }
}
