//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SliderInteractionModifier<Value: BinaryFloatingPoint>: ViewModifier {

    let value: Binding<Value>
    let total: Value
    let isScrollingEnabled: Bool
    let onEditingChanged: (Bool) -> Void
    let onFocusChanged: (Bool) -> Void

    func body(content: Content) -> some View {
        SliderContainerRepresentable(
            value: value,
            total: total,
            isScrollingEnabled: isScrollingEnabled,
            onEditingChanged: onEditingChanged,
            onFocusChanged: onFocusChanged
        )
        .overlay {
            content
                .allowsHitTesting(false)
        }
    }
}

private struct SliderContainerRepresentable<Value: BinaryFloatingPoint>: PlatformViewRepresentable {

    let value: Binding<Value>
    let total: Value
    let isScrollingEnabled: Bool
    let onEditingChanged: (Bool) -> Void
    let onFocusChanged: (Bool) -> Void

    func makeUIView(context: Context) -> UISliderContainer<Value> {
        UISliderContainer(
            value: value,
            total: total,
            isScrollingEnabled: isScrollingEnabled,
            onEditingChanged: onEditingChanged,
            onFocusChanged: onFocusChanged
        )
    }

    static func dismantleUIView(_ uiView: UISliderContainer<Value>, coordinator: ()) {
        uiView.stopDecelerating()
    }

    func updateUIView(_ uiView: UISliderContainer<Value>, context: Context) {
        uiView.update(
            value: value,
            total: total,
            isScrollingEnabled: isScrollingEnabled,
            onEditingChanged: onEditingChanged,
            onFocusChanged: onFocusChanged
        )
    }
}
