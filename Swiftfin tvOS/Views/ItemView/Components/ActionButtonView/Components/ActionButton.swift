//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionButton<Content: View>: View {

        // MARK: - Mode

        private enum Mode {
            case button
            case menu
        }

        // MARK: - Environment Objects

        @Environment(\.isSelected)
        private var isSelected

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        // MARK: - Required Properties

        private let mode: Mode
        private let title: String
        private let icon: String

        // MARK: - Button Properties

        private let selectedIcon: String?
        private let onSelect: (() -> Void)?

        // MARK: - Menu Properties

        private let content: (() -> Content)?

        // MARK: - Body

        var body: some View {
            Group {
                switch mode {
                case .button:
                    Button(action: onSelect!) {
                        labelView
                    }
                case .menu:
                    Menu {
                        content?()
                    } label: {
                        labelView
                    }
                }
            }
            .focused($isFocused)
            .buttonStyle(ActionButtonStyle())
        }

        // MARK: - Label Views

        private var labelView: some View {
            ZStack {
                if mode == .button && isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isFocused ? AnyShapeStyle(HierarchicalShapeStyle.primary) :
                                AnyShapeStyle(HierarchicalShapeStyle.primary.opacity(0.5))
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isFocused ? Color.white : Color.white.opacity(0.5))
                }

                Label(title, systemImage: (mode == .button && isSelected) ? (selectedIcon ?? icon) : icon)
                    .hoverEffectDisabled()
                    .focusEffectDisabled()
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .labelStyle(.iconOnly)
            }
            .accessibilityLabel(title)
        }
    }
}

// MARK: - Initializers

extension ItemView.ActionButton {

    // MARK: Button Initializer

    init(
        _ title: String,
        icon: String,
        selectedIcon: String,
        onSelect: @escaping () -> Void
    ) where Content == EmptyView {
        self.mode = .button
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.onSelect = onSelect
        self.content = nil
    }

    // MARK: Menu Initializer

    init(
        _ title: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.mode = .menu
        self.title = title
        self.icon = icon
        self.selectedIcon = nil
        self.onSelect = nil
        self.content = content
    }
}

struct ActionButtonStyle: ButtonStyle {

    // MARK: - Focus State

    @Environment(\.isFocused)
    private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            configuration.label
                .modifier(ActionButtonScaleModifier(
                    size: geometry.size,
                    expansion: getExpansionAmount(isPressed: configuration.isPressed),
                    animationDuration: 0.15,
                    isPressed: configuration.isPressed,
                    isFocused: isFocused
                ))
        }
    }

    // MARK: - Expand a Fixed Pixel Amount

    private func getExpansionAmount(isPressed: Bool) -> CGFloat {
        if isPressed {
            return 4
        } else if isFocused {
            return 16
        } else {
            return 0
        }
    }
}

// MARK: - Fixed-Size Scale Modifier

/// Since these buttons are variable in size, a 10% increase is too much for the largest button size but too little for the smallest button
/// This Modifier ensures a fixed pixel expansion/contraction is used to ensure a consistent animation
struct ActionButtonScaleModifier: ViewModifier {

    // MARK: - Button Properties

    let size: CGSize

    // MARK: - Expansion Properties

    let expansion: CGFloat
    let animationDuration: Double

    // MARK: - Expansion Reason(s)

    let isPressed: Bool
    let isFocused: Bool

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .scaleEffect(calculateScaleFactor())
            .animation(
                .easeInOut(duration: animationDuration),
                value: isPressed || isFocused
            )
    }

    // MARK: - Calculate Percentage from Properties

    private func calculateScaleFactor() -> CGFloat {
        if expansion == 0 {
            return 1.0
        }
        let baseSize = max(size.width, size.height)

        guard baseSize > 0 else { return 1.0 }

        return (baseSize + (2 * expansion)) / baseSize
    }
}
