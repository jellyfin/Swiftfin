//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct UnwatchedIndicator: View {

    let size: CGFloat
    var count: Int?

    #if os(iOS)
    private let padding: CGFloat = 4
    private let bottomLeadingRadius: CGFloat = 5
    #else
    private let padding: CGFloat = 8
    private let bottomLeadingRadius: CGFloat = 10
    #endif

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear

            if let count, count > 0 {
                Text(count.description)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, padding)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: size, alignment: .center)
                    .frame(minWidth: size)
                    .background {
                        UnevenRoundedRectangle(bottomLeadingRadius: bottomLeadingRadius)
                            .foregroundStyle(.secondary)
                    }
            } else {
                Q3RightTriangle()
                    .frame(width: size, height: size)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct Q3RightTriangle: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        return path
    }
}
