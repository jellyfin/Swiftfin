//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol SliderContainerStyle: ViewStyle where Configuration == SliderContainerStyleConfiguration {}

/// A snapshot of the slider's interaction state.
///
/// - Note: Styles use `Double` regardless of the binding's numeric type.
struct SliderContainerStyleConfiguration {

    let isEditing: Bool
    let isFocused: Bool
    let isScrollingEnabled: Bool
    let value: Double
    let originValue: Double?
    let total: Double

    var progress: Double {
        progress(for: value)
    }

    var originProgress: Double? {
        originValue.map(progress(for:))
    }

    private func progress(for value: Double) -> Double {
        guard total.isFinite, total > 0, value.isFinite else { return 0 }
        return clamp(value / total, min: 0, max: 1)
    }
}

struct SliderContainerBody: ViewStyledView {

    let configuration: SliderContainerStyleConfiguration

    static var defaultStyle: CapsuleSliderStyle {
        CapsuleSliderStyle()
    }
}

extension View {

    func sliderContainerStyle(_ style: some SliderContainerStyle) -> some View {
        styledViewStyle(SliderContainerBody.self, style: style)
    }
}
