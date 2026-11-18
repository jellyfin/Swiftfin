//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension String {

    private var containsHTML: Bool {
        contains(#/<\/?[a-zA-Z][^>]*>|&(?:[a-zA-Z]+|#[0-9]+|#[xX][0-9a-fA-F]+);/#)
    }

    private var containsMarkdown: Bool {
        contains(#/(?:^|[^\w*])([*_]{1,2})[^\s*_](?:.*?[^\s*_])?\1(?:$|[^\w*])|~~.+?~~|`[^`]+`|\[[^\]]+\]\([^)\s]+\)/#)
    }

    var richText: AttributedString {
        var value: AttributedString

        if containsHTML {
            var parser = HTMLParser(escapingMarkdown.markdown)
            value = parser.parse()
        } else if containsMarkdown {
            value = markdown
        } else {
            return AttributedString(self)
        }

        for (link, range) in value.runs[\.link] {
            guard let link else { continue }

            // tvOS can't open links
            if UIDevice.isTV || !["http", "https", "mailto"].contains(link.scheme?.lowercased() ?? "") {
                value[range].link = nil
            }
        }

        return value
    }

    var plainText: String {
        String(richText.characters)
    }

    private var escapingMarkdown: String {
        replacing(#/(?<tag><\/?[a-zA-Z][^>]*>)|[\\`*_\[\]~]/#) { match in
            match.output.tag.map(String.init) ?? "\\" + match.output.0
        }
    }
}

// MARK: - Rules

extension String {

    private enum HTMLBreak: Comparable {

        case line
        case paragraph

        var text: String {
            switch self {
            case .line:
                .newLine
            case .paragraph:
                .newParagraph
            }
        }
    }

    private struct HTMLRule {

        var attributes = AttributeContainer()
        var intent: InlinePresentationIntent = []
        var htmlBreak: HTMLBreak?
        var childMarker: ((_ index: Int, _ depth: Int) -> String)?
        var compactsBreaks = false
        var preservesWhitespace = false
        var isHidden = false
        var isVoid = false
    }

    private enum HTMLTag: String {

        case a
        case b
        case blockquote
        case br
        case cite
        case code
        case del
        case dfn
        case div
        case em
        case h1
        case h2
        case h3
        case h4
        case h5
        case h6
        case hr
        case i
        case ins
        case kbd
        case li
        case ol
        case p
        case pre
        case s
        case samp
        case script
        case strike
        case strong
        case style
        case sub
        case sup
        case table
        case td
        case th
        case tr
        case tt
        case u
        case ul

        func rule(attributes: Substring) -> HTMLRule {
            switch self {
            case .a:
                HTMLRule(attributes: Self.href(in: attributes).map { AttributeContainer().link($0) } ?? AttributeContainer())
            case .b, .strong:
                HTMLRule(intent: .stronglyEmphasized)
            case .i, .em, .cite, .dfn:
                HTMLRule(intent: .emphasized)
            case .s, .strike, .del:
                HTMLRule(intent: .strikethrough)
            case .u, .ins:
                HTMLRule(attributes: AttributeContainer().underlineStyle(Text.LineStyle.single))
            case .code, .kbd, .samp, .tt:
                HTMLRule(intent: .code)
            case .pre:
                HTMLRule(intent: .code, htmlBreak: .paragraph, preservesWhitespace: true)
            case .sup:
                HTMLRule(attributes: AttributeContainer().baselineOffset(CGFloat(5)))
            case .sub:
                HTMLRule(attributes: AttributeContainer().baselineOffset(CGFloat(-3)))
            case .h1, .h2, .h3, .h4, .h5, .h6:
                HTMLRule(intent: .stronglyEmphasized, htmlBreak: .paragraph)
            case .p, .blockquote, .table:
                HTMLRule(htmlBreak: .paragraph)
            case .div:
                HTMLRule(htmlBreak: .line)
            case .br:
                HTMLRule(htmlBreak: .line, isVoid: true)
            case .hr:
                HTMLRule(htmlBreak: .paragraph, isVoid: true)
            case .ul:
                HTMLRule(htmlBreak: .paragraph, childMarker: { String(repeating: .space, count: $1 * 4) + .bullet + .space })
            case .ol:
                HTMLRule(htmlBreak: .paragraph, childMarker: { String(repeating: .space, count: $1 * 4) + "\($0)." + .space })
            case .li:
                HTMLRule(htmlBreak: .line, compactsBreaks: true)
            case .tr:
                HTMLRule(htmlBreak: .line, childMarker: { index, _ in index > 1 ? .space : .empty })
            case .td:
                HTMLRule()
            case .th:
                HTMLRule(intent: .stronglyEmphasized)
            case .script, .style:
                HTMLRule(isHidden: true)
            }
        }

        private static func href(in attributes: Substring) -> URL? {
            guard let match = attributes.firstMatch(
                of: #/\shref\s*=\s*(?:"(?<double>[^"]*)"|'(?<single>[^']*)'|(?<bare>[^\s"']+))/#.ignoresCase()
            ) else { return nil }

            let value = match.output.double ?? match.output.single ?? match.output.bare ?? ""

            return URL(string: String(value).replacing("&amp;", with: "&"))
        }
    }
}

// MARK: - Parser

extension String {

    private struct HTMLParser {

        private struct OpenTag {

            let tag: HTMLTag
            let rule: HTMLRule
            var childCount = 0
        }

        private let source: AttributedString
        private let isHTML: Bool

        private var result = AttributedString()
        private var openTags: [OpenTag] = []
        private var pendingBreak: HTMLBreak?

        init(_ source: AttributedString) {
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

        private func isOpen(where predicate: (HTMLRule) -> Bool) -> Bool {
            openTags.contains { predicate($0.rule) }
        }

        private mutating func resolveTags(in range: Range<AttributedString.Index>) {
            let html = String(source[range].characters)

            for match in html.matches(of: #/<(?<closing>/?)(?<name>[a-zA-Z0-9]+)(?<attributes>[^>]*)/#) {
                guard let tag = HTMLTag(rawValue: match.output.name.lowercased()) else { continue }

                if match.output.closing.isNotEmpty {
                    close(tag)
                } else {
                    let rule = tag.rule(attributes: match.output.attributes)

                    if rule.isVoid || !match.output.attributes.hasSuffix("/") {
                        open(tag, rule: rule)
                    }
                }
            }
        }

        private mutating func open(_ tag: HTMLTag, rule: HTMLRule) {
            requestBreak(rule.htmlBreak, stacks: rule.isVoid)

            if let parent = openTags.indices.last {
                openTags[parent].childCount += 1

                let depth = openTags[..<parent].count { $0.rule.childMarker != nil }

                if let marker = openTags[parent].rule.childMarker?(openTags[parent].childCount, depth) {
                    append(AttributedString(marker), preservingWhitespace: true)
                }
            }

            if !rule.isVoid {
                openTags.append(OpenTag(tag: tag, rule: rule))
            }
        }

        private mutating func close(_ tag: HTMLTag) {
            guard let index = openTags.lastIndex(where: { $0.tag == tag }) else { return }

            let closed = openTags.remove(at: index)

            requestBreak(closed.rule.htmlBreak, stacks: false)
        }

        private mutating func requestBreak(_ htmlBreak: HTMLBreak?, stacks: Bool) {
            guard var htmlBreak else { return }

            if stacks, pendingBreak != nil {
                htmlBreak = .paragraph
            }

            if isOpen(where: \.compactsBreaks) {
                htmlBreak = .line
            }

            pendingBreak = Swift.max(pendingBreak ?? htmlBreak, htmlBreak)
        }

        private mutating func appendRun(_ run: AttributedString.Runs.Run) {
            guard !isOpen(where: \.isHidden) else { return }

            var text = AttributedString(source[run.range])

            if isHTML, !isOpen(where: \.preservesWhitespace) {
                let collapsed = String(text.characters).replacing(#/\s+/#) { match in
                    match.output.filter(\.isNewline).count > 1 ? String.newParagraph : .space
                }

                text = AttributedString(collapsed, attributes: run.attributes)
            }

            let intent = openTags.reduce(run.inlinePresentationIntent ?? []) { $0.union($1.rule.intent) }
            text.inlinePresentationIntent = intent.isEmpty ? nil : intent

            for openTag in openTags {
                text.mergeAttributes(openTag.rule.attributes)
            }

            append(text, preservingWhitespace: isOpen(where: \.preservesWhitespace))
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

                result.append(AttributedString(pendingBreak.text))
            }

            pendingBreak = nil
            result.append(text)
        }
    }
}
