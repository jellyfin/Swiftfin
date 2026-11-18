//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension String {

    var richText: AttributedString {
        var value: AttributedString

        if contains(#/<\/?[a-zA-Z][^>]*>|&(?:[a-zA-Z]+|#[0-9]+|#[xX][0-9a-fA-F]+);/#) {
            let literalTags = #/<(code|kbd|pre|samp|script|style|tt)\b[^>]*>.*?<\/\1\s*>/#.ignoresCase().dotMatchesNewlines()
            let protected = replacing(literalTags) { match in
                match.output.0.replacing(#/(?<tag><\/?[a-zA-Z][^>]*>)|[\\`*_\[\]~]/#) { character in
                    character.output.tag.map(String.init) ?? "\\" + character.output.0
                }
            }
            var parser = HTMLParser(protected.markdown)
            value = parser.parse()
        } else if contains(#/(?:^|[^\w*])([*_]{1,2})[^\s*_](?:.*?[^\s*_])?\1(?:$|[^\w*])|~~.+?~~|`[^`]+`|\[[^\]]+\]\([^)\s]+\)/#) {
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
        richText.plainText
    }
}

extension AttributedString {

    var plainText: String {
        String(characters)
            .replacing(#/\s+/#, with: String.space)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Rules

extension String {

    private enum HTMLBreak: Comparable {

        case line
        case paragraph
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
                Self.script(baselineOffset: 5)
            case .sub:
                Self.script(baselineOffset: -3)
            case .h1:
                Self.heading(.title)
            case .h2:
                Self.heading(.title2)
            case .h3:
                Self.heading(.title3)
            case .h4:
                Self.heading(.headline)
            case .h5:
                Self.heading(.subheadline)
            case .h6:
                Self.heading(.footnote)
            case .p, .blockquote, .table, .tr:
                HTMLRule(htmlBreak: .paragraph)
            case .div, .td:
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
            case .th:
                HTMLRule(intent: .stronglyEmphasized, htmlBreak: .line)
            case .script, .style:
                HTMLRule(isHidden: true)
            }
        }

        private static func heading(_ font: Font) -> HTMLRule {
            HTMLRule(attributes: AttributeContainer().font(font), intent: .stronglyEmphasized, htmlBreak: .paragraph)
        }

        private static func script(baselineOffset: CGFloat) -> HTMLRule {
            HTMLRule(attributes: AttributeContainer().font(Font.caption2).baselineOffset(baselineOffset))
        }

        private static func href(in attributes: Substring) -> URL? {
            guard let match = attributes.firstMatch(
                of: #/\shref\s*=\s*(?:"(?<double>[^"]*)"|'(?<single>[^']*)'|(?<bare>[^\s"']+))/#.ignoresCase()
            ) else { return nil }

            let value = match.output.double ?? match.output.single ?? match.output.bare ?? ""

            return String(value).replacing("&amp;", with: "&").url
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
                    if let index = openTags.lastIndex(where: { $0.tag == tag }) {
                        requestBreak(for: openTags.remove(at: index).rule)
                    }
                } else {
                    let rule = tag.rule(attributes: match.output.attributes)

                    if rule.isVoid || !match.output.attributes.hasSuffix("/") {
                        open(tag, rule: rule)
                    }
                }
            }
        }

        private mutating func open(_ tag: HTMLTag, rule: HTMLRule) {
            requestBreak(for: rule)

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

        private mutating func requestBreak(for rule: HTMLRule) {
            guard var htmlBreak = rule.htmlBreak else { return }

            if rule.isVoid, pendingBreak != nil {
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
            let preservesWhitespace = isOpen(where: \.preservesWhitespace)

            if isHTML, !preservesWhitespace {
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
}
