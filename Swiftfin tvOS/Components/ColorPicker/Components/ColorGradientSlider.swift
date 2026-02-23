//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ColorGradientSlider: View {

    @Binding
    private var color: Color

    private let component: WritableKeyPath<Color.RGBA, CGFloat>

    init(color: Binding<Color>, component: WritableKeyPath<Color.RGBA, CGFloat>) {
        self._color = color
        self.component = component
    }

    var body: some View {
        SliderContainer(
            value: $color.rgbaComponents.map(
                getter: { $0[keyPath: component] * 255 },
                setter: { value in
                    var rgba = color.rgbaComponents
                    rgba[keyPath: component] = value / 255
                    return rgba
                }
            ),
            total: 255
        ) {
            ColorGradientSliderContent(
                color: color,
                component: component
            )
        }
        .onMoveCommand { direction in
            let step: CGFloat = 5

            switch direction {
            case .left:
                color.rgbaComponents[keyPath: component] = max(0, (color.rgbaComponents[keyPath: component] * 255 - step) / 255)
            case .right:
                color.rgbaComponents[keyPath: component] = min(1, (color.rgbaComponents[keyPath: component] * 255 + step) / 255)
            default:
                break
            }
        }
    }
}

private struct ColorGradientSliderContent: SliderContentView {

    @EnvironmentObject
    var sliderState: SliderContainerState<CGFloat>

    @State
    private var contentSize: CGSize = .zero

    private let color: Color
    private let component: WritableKeyPath<Color.RGBA, CGFloat>

    init(color: Color, component: WritableKeyPath<Color.RGBA, CGFloat>) {
        self.color = color
        self.component = component
    }

    private var progress: CGFloat {
        sliderState.value / 255
    }

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        color.with(rgba: component, value: 0),
                        color.with(rgba: component, value: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(alignment: .leading) {
                Circle()
                    .fill(color)
                    .overlay {
                        Circle()
                            .stroke(sliderState.isFocused ? Color.white : Color.black, lineWidth: 7)
                    }
                    .padding(7)
                    .scaleEffect(sliderState.isFocused ? 1.4 : 1)
                    .offset(x: (contentSize.width - contentSize.height) * progress)
            }
            .trackingSize($contentSize)
            .animation(.linear(duration: 0.1), value: sliderState.isFocused)
    }
}
