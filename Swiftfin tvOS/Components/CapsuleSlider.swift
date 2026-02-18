//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CapsuleSlider<Value: BinaryFloatingPoint>: View {

    @Binding
    private var value: Value

    @FocusState
    private var isFocused: Bool

    private let total: Value
    private var originProgress: Value?
    private var onEditingChanged: (Bool) -> Void

    init(value: Binding<Value>, total: Value) {
        self._value = value
        self.total = total
        self.onEditingChanged = { _ in }
    }

    var body: some View {
        SliderContainer(
            value: $value,
            total: total,
            originProgress: originProgress,
            onEditingChanged: onEditingChanged
        ) {
            CapsuleSliderContent()
        }
    }
}

extension CapsuleSlider {

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }

    func originProgress(_ value: Value?) -> Self {
        copy(modifying: \.originProgress, with: value)
    }
}

private struct CapsuleSliderContent: SliderContentView {

    @EnvironmentObject
    var sliderState: SliderContainerState<Double>

    private let borderWidth = 1.5

    var body: some View {
        ProgressView(value: sliderState.value, total: sliderState.total)
            .progressViewStyle(PlaybackProgressViewStyle(cornerStyle: .round))
            .frame(height: 30)
            .overlay {
                Capsule()
                    .strokeBorder(
                        Color.white.opacity(sliderState.isFocused ? 1 : 0.4),
                        lineWidth: 1.5
                    )
            }
            .overlay {
                if let originValue = sliderState.originValue, sliderState.total > 0 {
                    GeometryReader { geometry in
                        let fraction = clamp(originValue / sliderState.total, min: 0, max: 1)
                        Capsule()
                            .fill(Color.gray)
                            .frame(width: 4, height: geometry.size.height - (borderWidth * 2))
                            .position(x: geometry.size.width * fraction, y: geometry.size.height / 2)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: sliderState.originValue != nil)
    }
}
