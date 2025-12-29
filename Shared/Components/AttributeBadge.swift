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

    enum Style {
        case fill
        case outline
    }

    private let style: Style
    private let content: Content

    init(
        style: Style,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }

    private var resolvedFont: Font {
        font ?? .caption.weight(.semibold)
    }

    @ViewBuilder
    private var innerBody: some View {
        if style == .fill {
            content
                .padding(.init(vertical: 1, horizontal: 4))
                .hidden()
                .background {
                    RoundedRectangle(cornerRadius: 2)
                        .inverseMask {
                            content
                                .padding(.init(vertical: 1, horizontal: 4))
                        }
                }
        } else {
            content
                .padding(.init(vertical: 1, horizontal: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(lineWidth: 1)
                )
        }
    }

    var body: some View {
        innerBody
            .labelStyle(AttributeBadgeLabelStyle())
            .font(resolvedFont)
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
