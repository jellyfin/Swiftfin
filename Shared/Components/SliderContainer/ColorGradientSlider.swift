//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ColorGradientSlider: View {

    let color: Binding<Color>
    let component: WritableKeyPath<Color.RGBA, CGFloat>

    var body: some View {
        SliderContainer(
            value: color.rgbaComponents.map(
                getter: { $0[keyPath: component] * 255 },
                setter: { value in
                    var rgba = color.wrappedValue.rgbaComponents
                    rgba[keyPath: component] = value / 255
                    return rgba
                }
            ),
            total: 255
        )
        .sliderContainerStyle(.colorGradient(color: color.wrappedValue, component: component))
        #if os(tvOS)
        .onMoveCommand { direction in
            let step: CGFloat = 5

            switch direction {
            case .left:
                color.wrappedValue.rgbaComponents[keyPath: component] = max(
                    0,
                    (color.wrappedValue.rgbaComponents[keyPath: component] * 255 - step) / 255
                )
            case .right:
                color.wrappedValue.rgbaComponents[keyPath: component] = min(
                    1,
                    (color.wrappedValue.rgbaComponents[keyPath: component] * 255 + step) / 255
                )
            default:
                break
            }
        }
        #endif
    }
}
