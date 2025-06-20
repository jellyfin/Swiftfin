//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension ButtonStyle where Self == ToolbarPillButtonStyle {

    static var toolbarPill: ToolbarPillButtonStyle {
        ToolbarPillButtonStyle(primary: Defaults[.accentColor], secondary: .secondary)
    }

    static func toolbarPill(_ primary: Color, _ secondary: Color = Color.secondary) -> ToolbarPillButtonStyle {
        ToolbarPillButtonStyle(primary: primary, secondary: secondary)
    }

    static var action: ActionButtonStyle {
        ActionButtonStyle()
    }
}

// TODO: don't take `Color`, take generic `ShapeStyle`
struct ToolbarPillButtonStyle: ButtonStyle {

    @Environment(\.isEnabled)
    private var isEnabled

    let primary: Color
    let secondary: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? primary.overlayColor : secondary)
            .font(.headline)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(isEnabled ? primary : secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(isEnabled && !configuration.isPressed ? 1 : 0.5)
    }
}

struct ActionButtonStyle: ButtonStyle {

    // MARK: - Environment Objects

    @Environment(\.isSelected)
    private var isSelected

    // MARK: - Focus State

    @FocusState
    private var isFocused: Bool

    // MARK: - Body

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(isSelected ? .secondary : .tertiary)

            configuration.label
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .symbolRenderingMode(.monochrome)
                .labelStyle(.iconOnly)
        }
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.2 : 1.0)
        .animation(
            .spring(response: 0.2, dampingFraction: 1), value: isFocused
        )
    }
}
