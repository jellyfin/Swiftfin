//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct DownloadProgressStyle: ProgressViewStyle {

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        let progress = configuration.fractionCompleted ?? 0

        AlternateLayoutView {
            Image(systemName: "arrow.down.circle")
        } content: { size in
            Image(systemName: "arrow.down.circle.dotted")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.primary, .tertiary)
                .overlay {
                    Image(systemName: "arrow.down.circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.clear, .primary)
                        .mask {
                            ProgressWedge(progress: progress)
                        }
                }
                .frame(width: size.width, height: size.height)
                .animation(.linear(duration: 0.15), value: progress)
        }
    }

    private struct ProgressWedge: Shape {

        var progress: Double

        var animatableData: Double {
            get { progress }
            set { progress = newValue }
        }

        func path(in rect: CGRect) -> Path {
            var path = Path()
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = max(rect.width, rect.height)

            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(-90 + 360 * progress),
                clockwise: false
            )
            path.closeSubpath()
            return path
        }
    }
}
