//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SliderContainer<Value: BinaryFloatingPoint>: View {

    struct SliderContainerState: Equatable {

        var isEditing = false
        var isFocused = false
    }

    @State
    private var containerState = SliderContainerState()

    @Binding
    private var value: Value
    private let total: Value
    private let isScrollingEnabled: Bool
    private let originProgress: Value?
    private var onEditingChanged: (Bool) -> Void

    #if os(iOS)
    private var translationBinding: Binding<CGPoint> = .constant(.zero)
    private var valueDamping: Double = 1
    private var gesturePadding: CGFloat = 0
    #endif

    init(
        value: Binding<Value>,
        total: Value = 1,
        isScrollingEnabled: Bool = true,
        originProgress: Value? = nil,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self._value = value
        self.total = total.isFinite && total > 0 ? total : 1
        self.isScrollingEnabled = isScrollingEnabled
        self.originProgress = originProgress
        self.onEditingChanged = onEditingChanged
    }

    private var interaction: SliderInteractionModifier<Value> {
        #if os(tvOS)
        SliderInteractionModifier(
            value: $value,
            total: total,
            isScrollingEnabled: isScrollingEnabled,
            onEditingChanged: setEditing,
            onFocusChanged: { containerState.isFocused = $0 }
        )
        #else
        SliderInteractionModifier(
            value: $value,
            total: total,
            isScrollingEnabled: isScrollingEnabled,
            isEditing: containerState.isEditing,
            translationBinding: translationBinding,
            valueDamping: valueDamping,
            gesturePadding: gesturePadding,
            onEditingChanged: setEditing
        )
        #endif
    }

    var body: some View {
        SliderContainerBody(configuration: .init(
            isEditing: containerState.isEditing,
            isFocused: containerState.isFocused,
            isScrollingEnabled: isScrollingEnabled,
            value: Double(value),
            originValue: originProgress.map { Double($0) },
            total: Double(total)
        ))
        .modifier(interaction)
        .onChange(of: isScrollingEnabled) {
            if !isScrollingEnabled {
                setEditing(false)
            }
        }
    }

    private func setEditing(_ isEditing: Bool) {
        guard containerState.isEditing != isEditing else { return }
        containerState.isEditing = isEditing
        onEditingChanged(isEditing)
    }
}

extension SliderContainer {

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }
}

#if os(iOS)
extension SliderContainer {

    func translation(_ binding: Binding<CGPoint>) -> Self {
        copy(modifying: \.translationBinding, with: binding)
    }

    func valueDamping(_ damping: Double) -> Self {
        copy(modifying: \.valueDamping, with: damping.isFinite ? clamp(damping, min: 0.01, max: 2) : 1)
    }

    func gesturePadding(_ padding: CGFloat) -> Self {
        copy(modifying: \.gesturePadding, with: padding.isFinite ? max(0, padding) : 0)
    }
}
#endif
