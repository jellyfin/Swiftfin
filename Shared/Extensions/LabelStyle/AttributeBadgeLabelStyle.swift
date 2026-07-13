//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension LabelStyle where Self == FillAttributeBadgeLabelStyle {

    static var attributeBadgeFill: FillAttributeBadgeLabelStyle {
        FillAttributeBadgeLabelStyle()
    }
}

extension LabelStyle where Self == OutlineAttributeBadgeLabelStyle {

    static var attributeBadgeOutline: OutlineAttributeBadgeLabelStyle {
        OutlineAttributeBadgeLabelStyle()
    }
}

struct FillAttributeBadgeLabelStyle: LabelStyle {

    @Environment(\.font)
    private var font

    private var usedFont: Font {
        font ?? .caption.weight(.semibold)
    }

    private func content(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon

            configuration.title
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        content(configuration: configuration)
            .padding(.init(vertical: 1, horizontal: 4))
            .hidden()
            .background {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.primary)
                    .inverseMask {
                        content(configuration: configuration)
                            .padding(.init(vertical: 1, horizontal: 4))
                    }
            }
            .font(usedFont)
    }
}

struct OutlineAttributeBadgeLabelStyle: LabelStyle {

    @Environment(\.font)
    private var font

    private var usedFont: Font {
        font ?? .caption.weight(.semibold)
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon

            configuration.title
        }
        .foregroundStyle(.primary)
        .padding(.init(vertical: 1, horizontal: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 2)
                .stroke(.primary, lineWidth: 1)
        }
        .font(usedFont)
    }
}
