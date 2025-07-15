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

extension ButtonStyle where Self == OrnamentButtonStyle {

    static var ornament: OrnamentButtonStyle {
        OrnamentButtonStyle(Defaults[.accentColor])
    }

    static func ornament(_ primary: Color = .accentColor, iconOnly: Bool = false) -> OrnamentButtonStyle {
        OrnamentButtonStyle(primary, iconOnly: iconOnly)
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

struct OrnamentButtonStyle: ButtonStyle {

    // MARK: - Environment

    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isSelected)
    private var isSelected

    // MARK: - Configuration

    private let primary: Color
    private let iconOnly: Bool

    // MARK: - Initializer

    init(_ primary: Color, iconOnly: Bool = false) {
        self.primary = primary
        self.iconOnly = iconOnly
    }

    // MARK: - Body

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.semibold)
            .padding(10)
            .foregroundStyle(foregroundStyle(isPressed: configuration.isPressed))
            .background(
                ZStack {
                    backgroundShape
                        .fill(.ultraThinMaterial)
                    backgroundShape
                        .fill(backgroundFill(isPressed: configuration.isPressed))
                }
            )
            .contentShape(backgroundShape)
            .symbolRenderingMode(.palette)
            .aspectRatio(iconOnly ? 1 : nil, contentMode: .fit)
    }

    private var backgroundShape: AnyShape {
        iconOnly ? AnyShape(Circle()) : AnyShape(Capsule())
    }

    // MARK: - Background Color Fill

    private func backgroundFill(isPressed: Bool) -> Color {
        if !isEnabled {
            return Color.secondary.opacity(0.3)
        } else if isPressed {
            return Color.systemFill.opacity(0.7)
        } else if isSelected {
            return primary
        } else {
            return Color.systemFill.opacity(0.3)
        }
    }

    // MARK: - Foreground Color

    private func foregroundStyle(isPressed: Bool) -> Color {
        if !isEnabled {
            return Color.primary
        } else if isPressed {
            return primary.opacity(0.7)
        } else if isSelected {
            return Color.systemBackground
        } else {
            return primary
        }
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
