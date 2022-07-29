//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct ParallaxHeaderScrollView<Header: View, StaticOverlay: View, Content: View>: View {
    
    @State
    private var scrollViewOffset: CGFloat = 0
    
    let header: Header
    let staticOverlay: StaticOverlay
    let overlayAlignment: Alignment
    let headerHeight: CGFloat
    let content: () -> Content

    init(
        header: Header,
        staticOverlay: StaticOverlay,
        overlayAlignment: Alignment = .center,
        headerHeight: CGFloat,
        content: @escaping () -> Content
    ) {
        self.header = header
        self.staticOverlay = staticOverlay
        self.overlayAlignment = overlayAlignment
        self.headerHeight = headerHeight
        self.content = content
    }

    var body: some View {
        NavBarOffsetScrollView(scrollViewOffset: $scrollViewOffset, headerHeight: headerHeight) {
            ZStack {
//                GeometryReader { proxy in
//                    let yOffset = proxy.frame(in: .global).minY > 0 ? -proxy.frame(in: .global).minY : 0
//                    header
//                        .frame(width: proxy.size.width, height: proxy.size.height - yOffset)
//                        .overlay(staticOverlay, alignment: overlayAlignment)
//                        .offset(y: yOffset)
//                }
//                .frame(height: headerHeight)
                
                

                content()
                    .frame(maxWidth: .infinity)
            }
        }
        .onChange(of: scrollViewOffset) { newValue in
            print(newValue)
        }
    }
}
