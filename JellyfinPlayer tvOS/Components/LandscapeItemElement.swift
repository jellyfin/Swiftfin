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

struct CutOffShadow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tl = CGPoint(x: rect.minX, y: rect.minY)
        let tr = CGPoint(x: rect.maxX, y: rect.minY)
        let brs = CGPoint(x: rect.maxX, y: rect.maxY - 6)
        let brc = CGPoint(x: rect.maxX - 6, y: rect.maxY - 6)
        let bls = CGPoint(x: rect.minX + 6, y: rect.maxY)
        let blc = CGPoint(x: rect.minX + 6, y: rect.maxY - 6)

        path.move(to: tl)
        path.addLine(to: tr)
        path.addLine(to: brs)
        path.addRelativeArc(center: brc, radius: 6,
          startAngle: Angle.degrees(0), delta: Angle.degrees(90))
        path.addLine(to: bls)
        path.addRelativeArc(center: blc, radius: 6,
          startAngle: Angle.degrees(90), delta: Angle.degrees(90))

        return path
    }
}

struct LandscapeItemElement: View {
    @Environment(\.isFocused) var envFocused: Bool
    @State var focused: Bool = false
    @State var backgroundURL: URL?

    var item: BaseItemDto
    var inSeasonView: Bool?

    var body: some View {
        VStack {
            ImageView(src: (item.type == "Episode" && !(inSeasonView ?? false) ? item.getSeriesBackdropImage(maxWidth: 445) : item.getBackdropImage(maxWidth: 445)), bh: item.type == "Episode" ? item.getSeriesBackdropImageBlurHash() : item.getBackdropImageBlurHash())
                .frame(width: 445, height: 250)
                .cornerRadius(10)
                .ignoresSafeArea()
                .overlay(
                    ZStack {
                        if item.userData?.played ?? false {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.white)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(.systemBlue))
                        }
                    }.padding(2)
                    .opacity(1), alignment: .topTrailing).opacity(1)
                .overlay(
                    ZStack(alignment: .leading) {
                        if focused && item.userData?.playedPercentage != nil {
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.black, .clear]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                ))
                                .frame(width: 445, height: 90)
                                .mask(CutOffShadow())
                            VStack(alignment: .leading) {
                                Text("CONTINUE • \(item.getItemProgressString())")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .offset(y: 5)
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray)
                                        .opacity(0.4)
                                        .frame(minWidth: 100, maxWidth: .infinity, minHeight: 12, maxHeight: 12)
                                    RoundedRectangle(cornerRadius: 6)
                                         .fill(Color(red: 172/255, green: 92/255, blue: 195/255))
                                         .frame(width: CGFloat(item.userData?.playedPercentage ?? 0 * 4.45 - 0.16), height: 12)
                                 }
                            }.padding(12)
                        } else {
                            EmptyView()
                        }
                    }, alignment: .bottomLeading
                )
                .shadow(radius: focused ? 10.0 : 0, y: focused ? 10.0 : 0)
                .shadow(radius: focused ? 10.0 : 0, y: focused ? 10.0 : 0)
            if focused {
                if inSeasonView ?? false {
                  Text("\(item.getEpisodeLocator() ?? "") • \(item.name ?? "")")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .frame(width: 445)
                } else {
                    Text(item.type == "Episode" ? "\(item.seriesName ?? "") • \(item.getEpisodeLocator() ?? "")" : item.name ?? "")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .frame(width: 445)
                }
            } else {
                Spacer().frame(height: 25)
            }
        }
        .onChange(of: envFocused) { envFocus in
            withAnimation(.linear(duration: 0.15)) {
                self.focused = envFocus
            }

            if envFocus == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // your code here
                    if focused == true {
                        backgroundURL = item.getBackdropImage(maxWidth: 1080)
                        BackgroundManager.current.setBackground(to: backgroundURL!, hash: item.getBackdropImageBlurHash())
                    }
                }
            }
        }
        .scaleEffect(focused ? 1.1 : 1)
    }
}
