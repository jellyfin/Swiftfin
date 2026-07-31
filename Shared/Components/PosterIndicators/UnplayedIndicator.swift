//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct UnplayedIndicator: View {

    @Default(.accentColor)
    private var accentColor

    let count: Int?

    var body: some View {
        AlternateLayoutView(alignment: .topTrailing) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
        } content: { (size: CGSize) in
            if let count, count > 0 {
                Text(count.description)
                    .fontWeight(.semibold)
                    .foregroundStyle(accentColor.overlayColor)
                    .padding(.horizontal, UIDevice.isTV ? 8 : 4)
                    .fixedSize()
                    .frame(minWidth: size.width, minHeight: size.height)
                    .background {
                        UnevenRoundedRectangle(bottomLeadingRadius: UIDevice.isTV ? 18 : 6)
                            .fill(accentColor)
                    }
            } else {
                Q3RightTriangle()
                    .fill(accentColor)
            }
        }
    }
}

private struct Q3RightTriangle: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        return path
    }
}
