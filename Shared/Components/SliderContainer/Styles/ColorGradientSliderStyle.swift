//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ColorGradientSliderStyle: SliderContainerStyle {

    let color: Color
    let component: WritableKeyPath<Color.RGBA, CGFloat>

    func makeBody(configuration: SliderContainerStyleConfiguration) -> some View {
        ColorGradientSliderStyleContent(
            configuration: configuration,
            color: color,
            component: component
        )
    }
}

extension SliderContainerStyle where Self == ColorGradientSliderStyle {

    static func colorGradient(color: Color, component: WritableKeyPath<Color.RGBA, CGFloat>) -> ColorGradientSliderStyle {
        ColorGradientSliderStyle(color: color, component: component)
    }
}

private struct ColorGradientSliderStyleContent: View {

    @State
    private var contentSize: CGSize = .zero

    let configuration: SliderContainerStyleConfiguration
    let color: Color
    let component: WritableKeyPath<Color.RGBA, CGFloat>

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
                            .stroke(configuration.isFocused ? Color.white : Color.black, lineWidth: 7)
                    }
                    .padding(7)
                    .scaleEffect(configuration.isFocused ? 1.4 : 1)
                    .offset(x: (contentSize.width - contentSize.height) * CGFloat(configuration.progress))
            }
            .trackingSize($contentSize)
            .animation(.linear(duration: 0.1), value: configuration.isFocused)
    }
}
