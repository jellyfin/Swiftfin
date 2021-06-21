/*
 * JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import JellyfinAPI
import Combine

struct ProgressBar: Shape {
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

struct ContinueWatchingView: View {
    var items: [BaseItemDto]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            if items.count > 0 {
                LazyHStack {
                    Spacer().frame(width: 14)
                    ForEach(items, id: \.id) { item in
                        NavigationLink(destination: ItemView(item: item)) {
                            VStack(alignment: .leading) {
                                Spacer().frame(height: 10)
                                ImageView(src: item.getBackdropImage(maxWidth: 320), bh: item.getBackdropImageBlurHash())
                                    .frame(width: 320, height: 180)
                                    .cornerRadius(10)
                                    .overlay(
                                        Group {
                                            if item.type == "Episode" {
                                                Text("\(item.name ?? "")")
                                                    .font(.caption)
                                                    .padding(6)
                                                    .foregroundColor(.white)
                                            }
                                        }.background(Color.black)
                                        .opacity(0.8)
                                        .cornerRadius(10.0)
                                        .padding(6), alignment: .topTrailing
                                    )
                                    .overlay(
                                        Rectangle()
                                            .fill(Color(red: 172/255, green: 92/255, blue: 195/255))
                                            .mask(ProgressBar())
                                            .frame(width: CGFloat((item.userData?.playedPercentage ?? 0) * 3.2), height: 7)
                                            .padding(0), alignment: .bottomLeading
                                    )
                                Text(item.seriesName ?? item.name ?? "")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .frame(width: 320, alignment: .leading)
                                Spacer().frame(height: 5)
                            }
                        }
                        Spacer().frame(width: 16)
                    }
                    Spacer().frame(width: 2)
                }.frame(height: 215)
                .padding(.bottom, 10)
            }
        }
    }
}
