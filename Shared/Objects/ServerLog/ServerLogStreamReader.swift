//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Reads a log file line-by-line on demand. Each call to ``nextPage(maxLines:)`` advances
/// up to `maxLines` lines through the stream and returns them to the caller.
actor ServerLogStreamReader {

    struct Page {
        let lines: [String]
        let isFinal: Bool
    }

    private let url: URL

    private var handle: FileHandle?
    private var lineIterator: AsyncLineSequence<FileHandle.AsyncBytes>.AsyncIterator?
    private var isDone = false

    init(url: URL) {
        self.url = url
    }

    deinit {
        try? handle?.close()
    }

    func nextPage(maxLines: Int) async throws -> Page {
        if isDone {
            return Page(lines: [], isFinal: true)
        }

        try openIfNeeded()

        guard var iterator = lineIterator else {
            close()
            isDone = true
            return Page(lines: [], isFinal: true)
        }

        lineIterator = nil

        var lines: [String] = []
        lines.reserveCapacity(maxLines)

        var reachedEnd = false

        do {
            for _ in 0 ..< maxLines {
                guard let line = try await iterator.next() else {
                    reachedEnd = true
                    break
                }
                lines.append(line)
            }
        } catch {
            // Restore iterator so a retry resumes from the same position.
            lineIterator = iterator
            throw error
        }

        if reachedEnd {
            close()
            isDone = true
        } else {
            lineIterator = iterator
        }

        return Page(lines: lines, isFinal: reachedEnd)
    }

    private func openIfNeeded() throws {
        guard lineIterator == nil else { return }

        let handle = try FileHandle(forReadingFrom: url)
        self.handle = handle
        self.lineIterator = handle.bytes.lines.makeAsyncIterator()
    }

    private func close() {
        try? handle?.close()
        handle = nil
        lineIterator = nil
    }
}
