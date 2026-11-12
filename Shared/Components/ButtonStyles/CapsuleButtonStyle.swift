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

    static func capsule(
        selectionTint: Color = .white,
        focusTint: Color? = nil,
        isSelectionActive: Bool = true,
        anchor: HorizontalEdge? = nil
    ) -> Self {
        CapsuleButtonStyle(
            selectionTint: selectionTint,
            focusTint: focusTint,
            isSelectionActive: isSelectionActive,
            anchor: anchor
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

        init(_ controlSize: ControlSize, layout: ViewLayout) {
            switch controlSize {
            case .mini:
                self.font = .caption2
                self.horizontalPadding = layout.value(standard: 6, large: 12)
                self.verticalPadding = layout.value(standard: 2, large: 4)
                self.minimumHeight = layout.value(standard: 20, large: 40)
                self.labelSpacing = layout.value(standard: 2, large: 4)

            case .small:
                self.font = .footnote
                self.horizontalPadding = layout.value(standard: 8, large: 16)
                self.verticalPadding = layout.value(standard: 4, large: 8)
                self.minimumHeight = layout.value(standard: 26, large: 52)
                self.labelSpacing = layout.value(standard: 2, large: 4)

            case .regular:
                self.font = .callout
                self.horizontalPadding = layout.value(standard: 10, large: 20)
                self.verticalPadding = layout.value(standard: 5, large: 10)
                self.minimumHeight = layout.value(standard: 30, large: 60)
                self.labelSpacing = layout.value(standard: 4, large: 8)

            case .large:
                self.font = .headline
                self.horizontalPadding = layout.value(standard: 12, large: 24)
                self.verticalPadding = layout.value(standard: 6, large: 12)
                self.minimumHeight = layout.value(standard: 36, large: 72)
                self.labelSpacing = layout.value(standard: 5, large: 10)

            case .extraLarge:
                self.font = .title3
                self.horizontalPadding = layout.value(standard: 16, large: 32)
                self.verticalPadding = layout.value(standard: 8, large: 16)
                self.minimumHeight = layout.value(standard: 44, large: 88)
                self.labelSpacing = layout.value(standard: 6, large: 12)

            @unknown default:
                self = CapsuleControlMetrics(.regular, layout: layout)
            }
        }
    }

    @AdaptiveLayout
    private var viewLayout

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
    var anchor: HorizontalEdge?

    private var metrics: CapsuleControlMetrics {
        CapsuleControlMetrics(controlSize, layout: viewLayout)
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
            .frame(width: anchor == nil ? nil : metrics.minimumHeight, alignment: anchor == .leading ? .leading : .trailing)
    }
}
