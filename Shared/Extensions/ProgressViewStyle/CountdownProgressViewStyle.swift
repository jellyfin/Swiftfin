//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CountdownProgressViewStyle: ProgressViewStyle {

    @State
    private var contentSize: CGSize = .zero

    @ContentBuilder
    func makeBody(configuration: Configuration) -> some View {
        let lineWidth = contentSize.width * 0.08
        let innerWidth = max(contentSize.width - lineWidth * 3, 0)

        ZStack {
            Circle()
                .stroke(.primary, lineWidth: lineWidth)
                .opacity(0.25)

            Circle()
                .trim(from: 0, to: 1 - (configuration.fractionCompleted ?? 0))
                .stroke(.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            configuration.currentValueLabel
                .font(.system(size: innerWidth * 0.6, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .frame(width: innerWidth * 0.8)
                .foregroundStyle(.primary)
        }
        .padding(lineWidth / 2)
        .trackingSize($contentSize)
    }
}
