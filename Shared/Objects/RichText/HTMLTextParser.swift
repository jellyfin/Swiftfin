//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct HTMLTextParser {

    private struct OpenTag {

        let tag: HTMLTag
        let attributes: AttributeContainer
        var childCount = 0
    }

    private static let literalElementPattern = #/<(code|kbd|pre|samp|script|style|tt)\b[^>]*>.*?<\/\1\s*>/#
        .ignoresCase()
        .dotMatchesNewlines()
    private static let markdownCharacterPattern = #/(?<tag><\/?[a-zA-Z][^>]*>)|[\\`*_\[\]~]/#
    private static let tagPattern = #/<(?<closing>/?)(?<name>[a-zA-Z0-9]+)(?<attributes>[^>]*)/#
    private static let whitespacePattern = #/\s+/#

    private let source: AttributedString
    private let isHTML: Bool

    private var result = AttributedString()
    private var openTags: [OpenTag] = []
    private var pendingBreak: HTMLTag.LineBreak?

    init(_ html: String) {
        let source = html.replacing(Self.literalElementPattern) { element in
            element.output.0.replacing(Self.markdownCharacterPattern) { match in
                match.output.tag.map(String.init) ?? "\\" + match.output.0
            }
        }
        .markdown

        self.source = source
        self.isHTML = source.runs.contains { $0.inlinePresentationIntent?.contains(.inlineHTML) == true }
    }

    mutating func parse() -> AttributedString {
        for run in source.runs {
            if run.inlinePresentationIntent?.contains(.inlineHTML) == true {
                resolveTags(in: run.range)
            } else {
                appendRun(run)
            }
        }

        while result.characters.last?.isWhitespace == true {
            result.characters.removeLast()
        }

        return result
    }

    private func isOpen(where predicate: (HTMLTag) -> Bool) -> Bool {
        openTags.contains { predicate($0.tag) }
    }

    private mutating func resolveTags(in range: Range<AttributedString.Index>) {
        let html = String(source[range].characters)

        for match in html.matches(of: Self.tagPattern) {
            guard let tag = HTMLTag(rawValue: match.output.name.lowercased()) else { continue }

            if match.output.closing.isNotEmpty {
                if let index = openTags.lastIndex(where: { $0.tag == tag }) {
                    requestBreak(for: openTags.remove(at: index).tag)
                }
            } else if tag.isVoid || !match.output.attributes.hasSuffix("/") {
                open(tag, attributes: tag.attributes(from: match.output.attributes))
            }
        }
    }

    private mutating func open(_ tag: HTMLTag, attributes: AttributeContainer) {
        requestBreak(for: tag)

        if let parent = openTags.indices.last {
            openTags[parent].childCount += 1

            let depth = openTags[..<parent].count { $0.tag.isList }

            if let marker = openTags[parent].tag.childMarker(index: openTags[parent].childCount, depth: depth) {
                append(AttributedString(marker), preservingWhitespace: true)
            }
        }

        if !tag.isVoid {
            openTags.append(OpenTag(tag: tag, attributes: attributes))
        }
    }

    private mutating func requestBreak(for tag: HTMLTag) {
        guard var lineBreak = tag.lineBreak else { return }

        if tag.isVoid, pendingBreak != nil {
            lineBreak = .paragraph
        }

        if isOpen(where: \.compactsLineBreaks) {
            lineBreak = .line
        }

        pendingBreak = max(pendingBreak ?? lineBreak, lineBreak)
    }

    private mutating func appendRun(_ run: AttributedString.Runs.Run) {
        guard !isOpen(where: \.isHidden) else { return }

        var text = AttributedString(source[run.range])
        let preservesWhitespace = isOpen(where: \.preservesWhitespace)

        if isHTML, !preservesWhitespace {
            let collapsed = String(text.characters).replacing(Self.whitespacePattern) { match in
                match.output.filter(\.isNewline).count > 1 ? String.newParagraph : .space
            }

            text = AttributedString(collapsed, attributes: run.attributes)
        }

        let intent = openTags.reduce(run.inlinePresentationIntent ?? []) { $0.union($1.tag.intent) }
        text.inlinePresentationIntent = intent.isEmpty ? nil : intent

        for openTag in openTags {
            text.mergeAttributes(openTag.attributes)
        }

        append(text, preservingWhitespace: preservesWhitespace)
    }

    private mutating func append(_ text: AttributedString, preservingWhitespace: Bool) {
        var text = text
        let isLineStart = pendingBreak != nil || result.characters.isEmpty || result.characters.last == "\n"

        if preservingWhitespace {
            if isLineStart, text.characters.first?.isNewline == true {
                text.characters.removeFirst()
            }
        } else if isLineStart {
            text.characters.trimPrefix(while: \.isWhitespace)
        } else if result.characters.last == " " {
            text.characters.trimPrefix { $0 == " " }
        }

        guard text.characters.isNotEmpty else { return }

        if let pendingBreak, result.characters.isNotEmpty {
            while result.characters.last == " " || result.characters.last == "\t" {
                result.characters.removeLast()
            }

            result.append(AttributedString(pendingBreak == .paragraph ? String.newParagraph : .newLine))
        }

        pendingBreak = nil
        result.append(text)
    }
}
