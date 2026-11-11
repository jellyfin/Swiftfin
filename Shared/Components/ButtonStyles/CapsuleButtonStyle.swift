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
                self.horizontalPadding = UIDevice.isTV ? 12 : 6
                self.verticalPadding = UIDevice.isTV ? 4 : 2
                self.minimumHeight = UIDevice.isTV ? 40 : 20
                self.labelSpacing = UIDevice.isTV ? 4 : 2

            case .small:
                self.font = .footnote
                self.horizontalPadding = UIDevice.isTV ? 16 : 8
                self.verticalPadding = UIDevice.isTV ? 8 : 4
                self.minimumHeight = UIDevice.isTV ? 52 : 26
                self.labelSpacing = UIDevice.isTV ? 4 : 2

            case .regular:
                self.font = .callout
                self.horizontalPadding = UIDevice.isTV ? 20 : 10
                self.verticalPadding = UIDevice.isTV ? 10 : 5
                self.minimumHeight = UIDevice.isTV ? 60 : 30
                self.labelSpacing = UIDevice.isTV ? 8 : 4

            case .large:
                self.font = .headline
                self.horizontalPadding = UIDevice.isTV ? 24 : 12
                self.verticalPadding = UIDevice.isTV ? 12 : 6
                self.minimumHeight = UIDevice.isTV ? 72 : 36
                self.labelSpacing = UIDevice.isTV ? 10 : 5

            case .extraLarge:
                self.font = .title3
                self.horizontalPadding = UIDevice.isTV ? 32 : 16
                self.verticalPadding = UIDevice.isTV ? 16 : 8
                self.minimumHeight = UIDevice.isTV ? 88 : 44
                self.labelSpacing = UIDevice.isTV ? 12 : 6

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

    @ContentBuilder
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

    @ContentBuilder
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
