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
final class PagingFileReader<Parser: LogParser>: ViewModel {

    @CasePathable
    enum Action {
        case start
        case getNextPage
        case refresh

        var transition: Transition {
            switch self {
            case .start, .refresh:
                .loop(.loading)
            case .getNextPage:
                .background(.loadingPage)
            }
        }
    }

    enum BackgroundState {
        case loadingPage
    }

    enum State {
        case initial
        case error
        case loading
        case content
    }

    @Published
    private(set) var elements: [Parser.Element] = []
    @Published
    private(set) var hasNextPage: Bool = true

    let url: URL
    let pageSize: Int

    private let initialParser: Parser
    private var parser: Parser
    private var handle: FileHandle?
    private var iterator: FileHandle.AsyncBytes.AsyncIterator?
    private var byteBuffer = Data()
    private var delimiterBytes = Data()

    init(url: URL, parser: Parser, pageSize: Int = 100) {
        self.url = url
        self.initialParser = parser
        self.parser = parser
        self.pageSize = pageSize
        super.init()
    }

    @Function(\Action.Cases.start)
    private func _start() async throws {
        try openIfNeeded()
        try await loadPage()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        resetStream()
        try openIfNeeded()
        try await loadPage()
    }

    @Function(\Action.Cases.getNextPage)
    private func _getNextPage() async throws {
        guard hasNextPage else { return }
        try await loadPage()
    }

    private func openIfNeeded() throws {
        guard handle == nil else { return }
        let h = try FileHandle(forReadingFrom: url)
        handle = h
        iterator = h.bytes.makeAsyncIterator()
        byteBuffer = Data()
        delimiterBytes = parser.delimiter.data(using: parser.encoding) ?? Data([0x0A])
        hasNextPage = true
    }

    private func resetStream() {
        try? handle?.close()
        handle = nil
        iterator = nil
        byteBuffer.removeAll()
        parser = initialParser
        elements = []
    }

    private func loadPage() async throws {
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

            // No delimiter in current buffer — accumulate 4KB more before searching again.
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

        if !newElements.isEmpty {
            elements.append(contentsOf: newElements)
        }
    }
}
