//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct GaugeProgressViewStyle: ProgressViewStyle {

    @Default(.accentColor)
    private var accentColor

    @State
    private var contentSize: CGSize = .zero

    private let lineWidthRatio: CGFloat
    private let systemImage: String?

    init(systemImage: String? = nil) {
        self.lineWidthRatio = systemImage == nil ? 0.2 : 0.125
        self.systemImage = systemImage
    }

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
                    lineWidth: contentSize.width * lineWidthRatio
                )

            Circle()
                .trim(from: 0, to: configuration.fractionCompleted ?? 0)
                .stroke(
                    accentColor,
                    style: StrokeStyle(
                        lineWidth: contentSize.width * lineWidthRatio,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .animation(.linear(duration: 0.1), value: configuration.fractionCompleted)
        .trackingSize($contentSize)
    }
}
