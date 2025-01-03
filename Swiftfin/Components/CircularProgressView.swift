//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// SwiftUI gauge style not available on iOS 15

struct GaugeProgressStyle: ProgressViewStyle {

    @Default(.accentColor)
    private var accentColor

    @State
    private var contentSize: CGSize = .zero

    private var lineWidthRatio: CGFloat
    private var systemImage: String?

    func makeBody(configuration: Configuration) -> some View {
        ZStack {

            if let systemImage {
                Image(systemName: systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: contentSize.width / 2.5, maxHeight: contentSize.height / 2.5)
                    .foregroundStyle(.secondary)
                    .padding(6)
            }

            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: contentSize.width / lineWidthRatio
                )

            Circle()
                .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                .stroke(
                    accentColor,
                    style: StrokeStyle(
                        lineWidth: contentSize.width / lineWidthRatio,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .animation(.linear(duration: 0.1), value: configuration.fractionCompleted)
        .trackingSize($contentSize)
    }
}

extension GaugeProgressStyle {

    init() {
        self.init(
            lineWidthRatio: 5,
            systemImage: nil
        )
    }

    init(systemImage: String) {
        self.init(
            lineWidthRatio: 8,
            systemImage: systemImage
        )
    }
}

extension ProgressViewStyle where Self == GaugeProgressStyle {

    static var gauge: GaugeProgressStyle {
        GaugeProgressStyle()
    }

    static func gauge(systemImage: String) -> GaugeProgressStyle {
        GaugeProgressStyle(systemImage: systemImage)
    }
}
