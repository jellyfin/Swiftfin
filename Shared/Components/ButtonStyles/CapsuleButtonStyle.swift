//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ButtonStyle where Self == CapsuleButtonStyle {

    static var capsule: Self {
        CapsuleButtonStyle()
    }

    static func capsule(selectionTint: Color = .white, focusTint: Color? = nil, isSelectionActive: Bool = true) -> Self {
        CapsuleButtonStyle(
            selectionTint: selectionTint,
            focusTint: focusTint,
            isSelectionActive: isSelectionActive
        )
    }
}

struct CapsuleButtonStyle: ButtonStyle {

    struct CapsuleControlMetrics {

        let font: Font
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        let minimumHeight: CGFloat
        let labelSpacing: CGFloat

        init(_ controlSize: ControlSize) {
            switch controlSize {
            case .mini:
                self.font = .caption2
                self.horizontalPadding = 6
                self.verticalPadding = 2
                self.minimumHeight = 20
                self.labelSpacing = 2
            case .small:
                self.font = .footnote
                self.horizontalPadding = 8
                self.verticalPadding = 4
                self.minimumHeight = 26
                self.labelSpacing = 2
            case .regular:
                self.font = .callout
                self.horizontalPadding = 10
                self.verticalPadding = 5
                self.minimumHeight = 30
                self.labelSpacing = 4
            case .large:
                self.font = .headline
                self.horizontalPadding = 16
                self.verticalPadding = 8
                self.minimumHeight = 44
                self.labelSpacing = 6
            case .extraLarge:
                self.font = .title3
                self.horizontalPadding = 20
                self.verticalPadding = 10
                self.minimumHeight = 52
                self.labelSpacing = 8
            @unknown default:
                self = CapsuleControlMetrics(.regular)
            }
        }
    }

    @Environment(\.controlSize)
    private var controlSize
    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isSelected)
    private var isSelected
    @Environment(\.isFocused)
    private var isFocused
    @Environment(\.font)
    private var font

    var selectionTint: Color = .white
    var focusTint: Color?
    var isSelectionActive: Bool = true

    private var metrics: CapsuleControlMetrics {
        CapsuleControlMetrics(controlSize)
    }

    private var isHighlighted: Bool {
        isSelected || (isEnabled && isFocused)
    }

    private var highlightTint: Color {
        isEnabled && isFocused ? focusTint ?? selectionTint : selectionTint
    }

    private var foregroundStyle: AnyShapeStyle {
        isHighlighted ? AnyShapeStyle(highlightTint.overlayColor) : AnyShapeStyle(HierarchicalShapeStyle.primary)
    }

    private var highlightOpacity: Double {
        guard isHighlighted else { return 0 }
        return isFocused || isSelectionActive ? 1 : 0.8
    }

    @ViewBuilder
    private var background: some View {
        // Keep the glass configuration stable as focus and selection change.
        Color.clear
            .backport
            .glassEffect(.regular.interactive(isEnabled), in: .capsule)
            .overlay {
                Capsule()
                    .fill(highlightTint)
                    .opacity(highlightOpacity)
            }
    }

    private func opacity(isPressed: Bool) -> Double {
        if !isEnabled {
            return 0.5
        }

        if isPressed {
            return 0.6
        }

        return 1
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font ?? metrics.font)
            .fontWeight(.semibold)
            .foregroundStyle(foregroundStyle)
            .symbolRenderingMode(.monochrome)
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.vertical, metrics.verticalPadding)
            .frame(minHeight: metrics.minimumHeight)
            .clipShape(.capsule)
            .background { background }
            .contentShape(.capsule)
            .scaleEffect(isEnabled && isFocused ? 1.05 : 1)
            .opacity(opacity(isPressed: configuration.isPressed))
            .shadow(color: isEnabled && isFocused ? .black.opacity(0.5) : .clear, radius: 10)
            .animation(.linear(duration: 0.1), value: isFocused)
            .animation(.linear(duration: 0.1), value: isSelected)
            .animation(.linear(duration: 0.1), value: isSelectionActive)
            .animation(.linear(duration: 0.1), value: configuration.isPressed)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
