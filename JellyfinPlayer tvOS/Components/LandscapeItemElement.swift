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

fileprivate struct CutOffShadow: Shape {
    let radius = 6.0;
    
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

struct LandscapeItemElement: View {
    @Environment(\.isFocused) var envFocused: Bool
    @State var focused: Bool = false;
    @State var backgroundURL: URL?;
    
    var item: BaseItemDto;
    
    var body: some View {
        VStack() {
            ImageView(src: item.getBackdropImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: 375), bh: item.getBackdropImageBlurHash())
                .frame(width: 375, height: 250)
                .cornerRadius(10)
                .overlay(
                    Group {
                        if(focused && item.userData?.playedPercentage != nil) {
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(LinearGradient(colors: [.black,.clear], startPoint: .bottom, endPoint: .top))
                                    .frame(width: 375, height: 90)
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
                                             .frame(width: CGFloat(item.userData?.playedPercentage ?? 0 * 3.59), height: 12)
                                     }
                                }.padding(8)
                            }
                        } else {
                            EmptyView()
                        }
                    }, alignment: .bottomLeading
                )
                .shadow(radius: focused ? 10.0 : 0, y: focused ? 10.0 : 0)
                .shadow(radius: focused ? 10.0 : 0, y: focused ? 10.0 : 0)
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
            
            if(envFocus == true) {
                backgroundURL = item.getBackdropImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: Int((UIScreen.main.currentMode?.size.width)!))
                BackgroundManager.current.setBackground(to: backgroundURL!, hash: item.getBackdropImageBlurHash())
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if(BackgroundManager.current.backgroundURL == backgroundURL) {
                        BackgroundManager.current.clearBackground()
                    }
                }
            }
        }
        .scaleEffect(focused ? 1.1 : 1)
    }
}
