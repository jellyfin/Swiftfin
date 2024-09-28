//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// SwiftUI gauge style not available on iOS 15

// TODO: refine
struct GaugeProgressStyle: ProgressViewStyle {

    @Default(.accentColor)
    private var accentColor

    var lineWidthRatio: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: 20 / lineWidthRatio
                )

            Circle()
                .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                .stroke(
                    accentColor,
                    style: StrokeStyle(
                        lineWidth: 20 / lineWidthRatio,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .animation(.linear(duration: 0.1), value: configuration.fractionCompleted)
//        .frame(height: 20)
    }
}

extension ProgressViewStyle where Self == GaugeProgressStyle {

    static var gauge: GaugeProgressStyle {
        GaugeProgressStyle()
    }

    static func gauge(lineWidthRatio: CGFloat) -> GaugeProgressStyle {
        GaugeProgressStyle(lineWidthRatio: lineWidthRatio)
    }
}
