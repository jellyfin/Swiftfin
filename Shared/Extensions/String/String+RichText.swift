//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension String {

    private static let allowedLinkSchemes: Set<String> = ["http", "https", "mailto"]
    private static let htmlPattern = #/<\/?[a-zA-Z][^>]*>|&(?:[a-zA-Z]+|#[0-9]+|#[xX][0-9a-fA-F]+);/#
    private static let markdownPattern = #/(?:^|[^\w*])([*_]{1,2})[^\s*_](?:.*?[^\s*_])?\1(?:$|[^\w*])|~~.+?~~|`[^`]+`|\[[^\]]+\]\([^)\s]+\)/#

    var attributedString: AttributedString {
        var value: AttributedString

        if contains(Self.htmlPattern) {
            var parser = HTMLTextParser(self)
            value = parser.parse()
        } else if contains(Self.markdownPattern) {
            value = markdown
        } else {
            value = AttributedString(self)
        }

        for (link, range) in value.runs[\.link] {
            guard let link else { continue }

            // tvOS can't open links
            if UIDevice.isTV || !Self.allowedLinkSchemes.contains(link.scheme?.lowercased() ?? "") {
                value[range].link = nil
            }
        }

        return value
    }

    var plainString: String {
        attributedString.plainString
    }
}

extension AttributedString {

    var plainString: String {
        String(characters)
            .replacing(#/\s+/#) { $0.output.contains(where: \.isNewline) ? String.newLine : .space }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
