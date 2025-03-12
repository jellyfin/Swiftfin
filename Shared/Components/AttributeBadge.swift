//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AttributeBadge<Content: View>: View {

    @Environment(\.font)
    private var font

    enum AttributeStyle {
        case fill
        case outline
    }

    private let style: AttributeStyle
    private let content: () -> Content

    private var usedFont: Font {
        font ?? .caption.weight(.semibold)
    }

    @ViewBuilder
    private var innerBody: some View {
        if style == .fill {
            content()
                .padding(.init(vertical: 1, horizontal: 4))
                .hidden()
                .background {
                    Color(UIColor.lightGray)
                        .cornerRadius(2)
                        .inverseMask {
                            content()
                                .padding(.init(vertical: 1, horizontal: 4))
                        }
                }
        } else {
            content()
                .foregroundStyle(Color(UIColor.lightGray))
                .padding(.init(vertical: 1, horizontal: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(UIColor.lightGray), lineWidth: 1)
                )
        }
    }

    var body: some View {
        innerBody
            .labelStyle(AttributeBadgeLabelStyle())
            .font(usedFont)
    }
}

extension AttributeBadge where Content == Text {

    init(
        style: AttributeStyle,
        title: @autoclosure @escaping () -> Text
    ) {
        self.init(style: style) {
            title()
        }
    }

    init(
        style: AttributeStyle,
        title: String
    ) {
        self.init(style: style) {
            Text(title)
        }
    }
}

extension AttributeBadge where Content == Label<Text, Image> {

    init(
        style: AttributeStyle,
        title: String,
        image: Image
    ) {
        self.style = style
        self.content = {
            Label { Text(title) } icon: { image }
        }
    }

    init(
        style: AttributeStyle,
        title: String,
        image: @escaping () -> Image
    ) {
        self.style = style
        self.content = {
            Label { Text(title) } icon: { image() }
        }
    }

    init(
        style: AttributeStyle,
        title: String,
        systemName: String
    ) {
        self.style = style
        self.content = {
            Label { Text(title) } icon: { Image(systemName: systemName) }
        }
    }

    init(
        style: AttributeStyle,
        title: Text,
        image: Image
    ) {
        self.style = style
        self.content = {
            Label { title } icon: { image }
        }
    }

    init(
        style: AttributeStyle,
        title: Text,
        image: @escaping () -> Image
    ) {
        self.style = style
        self.content = {
            Label { title } icon: { image() }
        }
    }

    init(
        style: AttributeStyle,
        title: Text,
        systemName: String
    ) {
        self.style = style
        self.content = {
            Label { title } icon: { Image(systemName: systemName) }
        }
    }
}

private struct AttributeBadgeLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon

            configuration.title
        }
    }
}
