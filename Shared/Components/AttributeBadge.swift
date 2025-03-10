//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AttributeBadge<Content: View>: View {

    enum AttributeStyle {
        case fill
        case outline
    }

    let style: AttributeStyle
    let content: () -> Content

    init(style: AttributeStyle, @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.content = content
    }

    var body: some View {
        if style == .fill {
            content()
                .font(.caption.weight(.semibold))
                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                .opacity(0)
                .background {
                    Color(UIColor.lightGray)
                        .cornerRadius(2)
                        .inverseMask {
                            content()
                                .font(.caption.weight(.semibold))
                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                        }
                }
        } else {
            content()
                .font(.caption.weight(.semibold))
                .foregroundColor(Color(UIColor.lightGray))
                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(UIColor.lightGray), lineWidth: 1)
                )
        }
    }
}
