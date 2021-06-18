//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI
import JellyfinAPI

private struct CutOffShadow: Shape {
    let radius = 6.0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tl = CGPoint(x: rect.minX, y: rect.minY)
        let tr = CGPoint(x: rect.maxX, y: rect.minY)
        let brs = CGPoint(x: rect.maxX, y: rect.maxY - radius)
        let brc = CGPoint(x: rect.maxX - radius, y: rect.maxY - radius)
        let bls = CGPoint(x: rect.minX + radius, y: rect.maxY)
        let blc = CGPoint(x: rect.minX + radius, y: rect.maxY - radius)

        path.move(to: tl)
        path.addLine(to: tr)
        path.addLine(to: brs)
        path.addRelativeArc(center: brc, radius: radius,
          startAngle: Angle.degrees(0), delta: Angle.degrees(90))
        path.addLine(to: bls)
        path.addRelativeArc(center: blc, radius: radius,
          startAngle: Angle.degrees(90), delta: Angle.degrees(90))

        return path
    }
}

struct PortraitItemElement: View {
    @Environment(\.isFocused) var envFocused: Bool
    @State var focused: Bool = false
    @State var backgroundURL: URL?

    var item: BaseItemDto

    var body: some View {
        VStack {
            ImageView(src: item.type == "Episode" ? item.getSeriesPrimaryImage(maxWidth: 200) : item.getPrimaryImage(maxWidth: 200), bh: item.type == "Episode" ? item.getSeriesPrimaryImageBlurHash() : item.getPrimaryImageBlurHash())
                .frame(width: 200, height: 300)
                .cornerRadius(10)
                .shadow(radius: focused ? 10.0 : 0)
                .shadow(radius: focused ? 10.0 : 0)
        }
        .onChange(of: envFocused) { envFocus in
            withAnimation(.linear(duration: 0.15)) {
                self.focused = envFocus
            }

            if envFocus == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // your code here
                    if self.focused == true {
                        backgroundURL = item.getBackdropImage(maxWidth: 1080)
                        BackgroundManager.current.setBackground(to: backgroundURL!, hash: item.getBackdropImageBlurHash())
                    }
                }
            }
        }
        .scaleEffect(focused ? 1.1 : 1)
    }
}
