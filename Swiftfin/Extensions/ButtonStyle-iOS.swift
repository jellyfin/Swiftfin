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
}

extension ButtonStyle where Self == ActionButtonStyle {

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
    @Environment(\.isEnabled)
    private var isEnabled

    // MARK: - Body

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(backgroundStyle)

            configuration.label
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(textStyle)
                .symbolRenderingMode(.monochrome)
        }
    }

    // MARK: - Text Style

    private var textStyle: AnyShapeStyle {
        isEnabled ? AnyShapeStyle(.primary) : AnyShapeStyle(Color.secondarySystemFill)
    }

    // MARK: - Background Style

    private var backgroundStyle: AnyShapeStyle {
        if isEnabled {
            return AnyShapeStyle(isSelected ? .secondary : .tertiary)
        } else {
            return AnyShapeStyle(Color.secondarySystemFill)
        }
    }
}
