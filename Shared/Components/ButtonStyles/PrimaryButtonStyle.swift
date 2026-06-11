//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension PrimitiveButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }
}

struct PrimaryButtonStyle: PrimitiveButtonStyle {

    @Environment(\.isEnabled)
    private var isEnabled

    @FocusState
    private var isFocused: Bool

    private func primaryStyle(configuration: Configuration) -> some ShapeStyle {
        if configuration.role == .destructive || configuration.role == .cancel {
            if isFocused {
                return AnyShapeStyle(HierarchicalShapeStyle.primary)
            } else {
                return AnyShapeStyle(Color.red)
            }
        } else {
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        }
    }

    private func secondaryStyle(configuration: Configuration) -> some ShapeStyle {
        if configuration.role == .destructive || configuration.role == .cancel {
            return AnyShapeStyle(
                Color.red.opacity(isFocused ? 1.0 : 0.15)
            )
        } else {
            if isEnabled {
                return AnyShapeStyle(HierarchicalShapeStyle.secondary)
            } else {
                return AnyShapeStyle(Color.gray)
            }
        }
    }

    @ViewBuilder
    private func contentView(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(secondaryStyle(configuration: configuration))
                .brightness(isFocused ? 0.15 : 0.0)
                .frame(idealHeight: 44)

            configuration.label
                .foregroundStyle(primaryStyle(configuration: configuration))
        }
        .font(.body)
        .fontWeight(.semibold)
    }

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            contentView(configuration: configuration)
        }
        .listRowInsets(.zero)
        .buttonStyle(.card)
        .focused($isFocused)
    }
}
