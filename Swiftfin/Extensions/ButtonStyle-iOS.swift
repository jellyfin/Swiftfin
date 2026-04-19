//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

/// - Important: On iOS, this is a `BorderlessButtonStyle` instead.
/// This is only used to allow platform shared views.
extension PrimitiveButtonStyle where Self == BorderlessButtonStyle {
    static var card: BorderlessButtonStyle {
        .init()
    }
}

extension ButtonStyle where Self == ToolbarPillButtonStyle {

    static var toolbarPill: ToolbarPillButtonStyle {
        ToolbarPillButtonStyle(primary: Defaults[.accentColor], secondary: .secondary)
    }

    static func toolbarPill(_ primary: Color, _ secondary: Color = Color.secondary) -> ToolbarPillButtonStyle {
        ToolbarPillButtonStyle(primary: primary, secondary: secondary)
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

extension ButtonStyle where Self == ToolbarCapsuleButtonStyle {

    static var toolbarCapsule: ToolbarCapsuleButtonStyle {
        ToolbarCapsuleButtonStyle()
    }
}

struct ToolbarCapsuleButtonStyle: ButtonStyle {

    @Default(.accentColor)
    private var accentColor

    @Environment(\.isSelected)
    private var isSelected

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .foregroundColor(isSelected ? accentColor : Color(UIColor.secondarySystemFill))
                    .opacity(0.5)
            }
            .overlay {
                Capsule()
                    .stroke(isSelected ? accentColor : Color(UIColor.secondarySystemFill), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

extension ButtonStyle where Self == IsPressedButtonStyle {

    static func isPressed(_ isPressed: @escaping (Bool) -> Void) -> IsPressedButtonStyle {
        IsPressedButtonStyle(isPressed: isPressed)
    }
}

struct IsPressedButtonStyle: ButtonStyle {

    let isPressed: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed, perform: isPressed)
    }
}
