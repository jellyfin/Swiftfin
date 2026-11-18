//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum HTMLTag: String {

    enum LineBreak: Comparable {

        case line
        case paragraph
    }

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

    private static let hrefPattern = #/\shref\s*=\s*(?:"(?<double>[^"]*)"|'(?<single>[^']*)'|(?<bare>[^\s"']+))/#.ignoresCase()

    var intent: InlinePresentationIntent {
        switch self {
        case .b, .h1, .h2, .h3, .h4, .h5, .h6, .strong, .th:
            .stronglyEmphasized
        case .cite, .dfn, .em, .i:
            .emphasized
        case .del, .s, .strike:
            .strikethrough
        case .code, .kbd, .pre, .samp, .tt:
            .code
        default:
            []
        }
    }

    var lineBreak: LineBreak? {
        switch self {
        case .blockquote, .h1, .h2, .h3, .h4, .h5, .h6, .hr, .ol, .p, .pre, .table, .tr, .ul:
            .paragraph
        case .br, .div, .li, .td, .th:
            .line
        default:
            nil
        }
    }

    var compactsLineBreaks: Bool {
        self == .li
    }

    var isHidden: Bool {
        self == .script || self == .style
    }

    var isList: Bool {
        self == .ol || self == .ul
    }

    var isVoid: Bool {
        self == .br || self == .hr
    }

    var preservesWhitespace: Bool {
        self == .pre
    }

    func attributes(from source: Substring) -> AttributeContainer {
        switch self {
        case .a:
            source.firstMatch(of: Self.hrefPattern)
                .flatMap { match in
                    String(match.output.double ?? match.output.single ?? match.output.bare ?? "")
                        .replacing("&amp;", with: "&")
                        .url
                }
                .map { AttributeContainer().link($0) } ?? AttributeContainer()

        case .h1:
            AttributeContainer().font(Font.title)

        case .h2:
            AttributeContainer().font(Font.title2)

        case .h3:
            AttributeContainer().font(Font.title3)

        case .h4:
            AttributeContainer().font(Font.headline)

        case .h5:
            AttributeContainer().font(Font.subheadline)

        case .h6:
            AttributeContainer().font(Font.footnote)

        case .ins, .u:
            AttributeContainer().underlineStyle(Text.LineStyle.single)

        case .sub:
            AttributeContainer().font(Font.caption2).baselineOffset(CGFloat(-3))

        case .sup:
            AttributeContainer().font(Font.caption2).baselineOffset(CGFloat(5))

        default:
            AttributeContainer()
        }
    }

    func childMarker(index: Int, depth: Int) -> String? {
        let indent = String(repeating: .space, count: depth * 4)

        return switch self {
        case .ol:
            indent + "\(index)." + .space
        case .ul:
            indent + .bullet + .space
        default:
            nil
        }
    }
}
