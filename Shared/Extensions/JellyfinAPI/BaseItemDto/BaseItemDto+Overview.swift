//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import UIKit

extension BaseItemDto {

    /// The overview with any HTML parsed, keeping only bold and italic emphasis.
    ///
    /// Fonts, colors, and links from the HTML are dropped so the text
    /// inherits the environment font when used with `Text`.
    ///
    /// - Important: HTML parsing uses the WebKit importer, which must run on
    ///   the main thread and is slow. Prefer on detail screens, not in scrolling lists.
    var attributedOverview: AttributedString? {
        overview.map(OverviewParser.parse)
    }

    /// The overview as plain text, with any HTML tags removed and entities decoded.
    var cleanedOverview: String? {
        attributedOverview.map { String($0.characters) }
    }
}

private enum OverviewParser {

    private final class Box {
        let value: AttributedString

        init(_ value: AttributedString) {
            self.value = value
        }
    }

    private static let cache = NSCache<NSString, Box>()

    static func parse(_ overview: String) -> AttributedString {
        // Only text containing something tag-shaped is treated as HTML,
        // so plain text like "5 < 6" keeps its own whitespace
        guard overview.range(of: "<[a-zA-Z/!]", options: .regularExpression) != nil else {
            return AttributedString(overview)
        }

        if let cached = cache.object(forKey: overview as NSString) {
            return cached.value
        }

        let parsed = parseHTML(overview) ?? AttributedString(overview)
        cache.setObject(Box(parsed), forKey: overview as NSString)
        return parsed
    }

    private static func parseHTML(_ html: String) -> AttributedString? {
        guard let data = html.data(using: .utf8),
              let imported = try? NSAttributedString(
                  data: data,
                  options: [
                      .documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue,
                  ],
                  documentAttributes: nil
              )
        else { return nil }

        var result = AttributedString()

        imported.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: imported.length)
        ) { value, range, _ in
            var run = AttributedString(imported.attributedSubstring(from: range).string)
            let traits = (value as? UIFont)?.fontDescriptor.symbolicTraits ?? []

            var intent: InlinePresentationIntent = []
            if traits.contains(.traitBold) {
                intent.insert(.stronglyEmphasized)
            }
            if traits.contains(.traitItalic) {
                intent.insert(.emphasized)
            }
            if !intent.isEmpty {
                run.inlinePresentationIntent = intent
            }

            result += run
        }

        // Block elements like <p> end with a newline
        while let last = result.characters.last, last.isNewline {
            result.characters.removeLast()
        }

        return result
    }
}
