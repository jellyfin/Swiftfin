//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct ServerLogContent: Hashable {

    let rawText: String
    let entries: [ServerLogEntry]

    /// Reads the file at `url` off the main actor and parses it when `parseEntries` is true.
    /// Both the file read and the parse pass happen inside the same detached task so the
    /// `.background(.downloading)` state on the view model covers the whole operation.
    static func load(from url: URL, parseEntries: Bool) async -> ServerLogContent {
        await Task.detached(priority: .userInitiated) {
            let rawText = readContents(at: url)
            let entries = parseEntries ? ServerLogParser.parse(rawText) : []
            return ServerLogContent(rawText: rawText, entries: entries)
        }.value
    }

    /// Attempts to read the contents of the log file.
    /// - Depending on what goes into the log, the encoding can vary.
    /// - Example: If I have an emoji in my logs it ends up as ascii.
    private static func readContents(at url: URL) -> String {
        var usedEncoding: String.Encoding = .utf8

        if let text = try? String(contentsOf: url, usedEncoding: &usedEncoding) {
            return text
        }

        guard let data = try? Data(contentsOf: url) else { return "" }

        return String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .utf16)
            ?? String(data: data, encoding: .ascii)
            ?? ""
    }
}
