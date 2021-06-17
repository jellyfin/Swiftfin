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

fileprivate struct ProgressBar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tl = CGPoint(x: rect.minX, y: rect.minY)
        let tr = CGPoint(x: rect.maxX, y: rect.minY)
        let br = CGPoint(x: rect.maxX, y: rect.maxY)
        let bls = CGPoint(x: rect.minX + 10, y: rect.maxY)
        let blc = CGPoint(x: rect.minX + 10, y: rect.maxY - 10)

        path.move(to: tl)
        path.addLine(to: tr)
        path.addLine(to: br)
        path.addLine(to: bls)
        path.addRelativeArc(center: blc, radius: 10,
          startAngle: Angle.degrees(90), delta: Angle.degrees(90))

        return path
    }
}

struct ContinueWatchingItem: View {
    @Environment(\.isFocused) var envFocused: Bool
    @State var focused: Bool = false;
    
    var item: BaseItemDto;
    
    var body: some View {
        VStack() {
            ImageView(src: item.getBackdropImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: 375), bh: item.getBackdropImageBlurHash())
                .frame(width: 375, height: 250)
                .cornerRadius(10)
                .overlay(
                    Rectangle()
                        .fill(Color(red: 172/255, green: 92/255, blue: 195/255))
                        .mask(ProgressBar())
                        .frame(width: CGFloat(item.userData?.playedPercentage ?? 0 * 3.75), height: 12)
                        .padding(6), alignment: .bottomLeading
                )
            if(focused) {
                Text(item.seriesName ?? item.name ?? "")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .frame(width: 375)
            } else {
                Spacer().frame(height: 25)
            }
        }
        .onChange(of: envFocused) { envFocus in
            withAnimation(.linear(duration: 0.15)) {
                self.focused = envFocus
            }
        }
        .scaleEffect(focused ? 1.1 : 1)
    }
}
