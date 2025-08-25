//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CapsuleSlider<Value: BinaryFloatingPoint>: View {

    @Binding
    private var value: Value

    @FocusState
    private var isFocused: Bool

    let total: Value

    init(value: Binding<Value>, total: Value) {
        self._value = value
        self.total = total
    }

    var body: some View {
        SliderContainer(
            value: $value,
            total: total,
            onEditingChanged: { _ in }
        ) {
            CapsuleSliderContent()
        }
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.3), value: isFocused)
        .foregroundStyle(isFocused ? Color.white : Color.white.opacity(0.8))
    }
}

private struct CapsuleSliderContent: SliderContentView {

    @EnvironmentObject
    var sliderState: SliderContainerState<Double>

    var body: some View {
        ProgressView(value: sliderState.value, total: sliderState.total)
            .progressViewStyle(PlaybackProgressViewStyle(cornerStyle: .round))
            .frame(height: 30)
            .padding()
    }
}
