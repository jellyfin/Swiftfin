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

    let url: URL
    let pageSize: Int

    private let initialParser: Parser
    private let delimiterBytes: Data
    private let readChunkSize = 64 * 1024

    private var handle: FileHandle?
    private var buffer = Data()
    private var cursor = 0
    private var parser: Parser

    init(
        url: URL,
        parser: Parser,
        pageSize: Int = 100
    ) {
        self.url = url
        self.initialParser = parser
        self.parser = parser
        self.pageSize = pageSize
        self.delimiterBytes = parser.delimiter.data(using: parser.encoding) ?? Data([0x0A])
        super.init()
    }

    // MARK: - Refresh

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {

        self.elements = []

        try open()
        try loadPage()
    }

    // MARK: - Get Next Page

    @Function(\Action.Cases.getNextPage)
    private func _getNextPage() async throws {
        guard hasNextPage else { return }

        if handle == nil {
            try open()
        }

        try loadPage()
    }

    private func open() throws {
        try? handle?.close()
        let h = try FileHandle(forReadingFrom: url)
        let size = try h.seekToEnd()
        try h.seek(toOffset: 0)
        handle = h
        buffer = Data()
        cursor = 0
        parser = initialParser
        elements = []
        hasNextPage = size > 0
    }

    private func loadPage() throws {
        guard let handle else {
            hasNextPage = false
            return
        }

        var newElements: [Parser.Element] = []

        while newElements.count < pageSize {
            while newElements.count < pageSize,
                  let range = buffer.range(
                      of: delimiterBytes,
                      in: cursor ..< buffer.count
                  )
            {
                let lineData = buffer.subdata(in: cursor ..< range.lowerBound)
                cursor = range.upperBound
                if let line = String(data: lineData, encoding: parser.encoding) {
                    newElements.append(contentsOf: parser.read(chunk: line))
                }
            }

            if newElements.count >= pageSize { break }

            // Compact the buffer when most of it is consumed, to keep the search range bounded.
            if cursor >= readChunkSize {
                buffer.removeSubrange(0 ..< cursor)
                cursor = 0
            }

            let chunk = try handle.read(upToCount: readChunkSize) ?? Data()

            if chunk.isEmpty {
                if cursor < buffer.count,
                   let line = String(
                       data: buffer.subdata(in: cursor ..< buffer.count),
                       encoding: parser.encoding
                   )
                {
                    newElements.append(contentsOf: parser.read(chunk: line))
                }
                buffer.removeAll()
                cursor = 0
                newElements.append(contentsOf: parser.flush())
                hasNextPage = false
                break
            }

            buffer.append(chunk)
        }

        if newElements.isNotEmpty {
            elements.append(contentsOf: newElements)
        }
    }
}
