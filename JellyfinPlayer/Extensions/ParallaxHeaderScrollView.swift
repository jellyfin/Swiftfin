//
//  ParallaxHeaderScrollView.swift
//  JellyfinPlayer
//
//  Created by PangMo5 on 2021/05/30.
//

import Foundation
import SwiftUI

struct ParallaxHeaderScrollView<Header: View, StaticOverlayView: View, Content: View>: View {
    var header: Header
    var staticOverlayView: StaticOverlayView
    var overlayAlignment: Alignment
    var headerHeight: CGFloat
    var content: () -> Content

    init(header: Header,
         staticOverlayView: StaticOverlayView,
         overlayAlignment: Alignment = .center,
         headerHeight: CGFloat,
         content: @escaping () -> Content)
    {
        self.header = header
        self.staticOverlayView = staticOverlayView
        self.overlayAlignment = overlayAlignment
        self.headerHeight = headerHeight
        self.content = content
    }

    var body: some View {
        ScrollView {
            GeometryReader { proxy in
                let yOffset = proxy.frame(in: .global).minY > 0 ? -proxy.frame(in: .global).minY : 0
                header
                    .frame(width: proxy.size.width, height: proxy.size.height - yOffset)
                    .overlay(staticOverlayView, alignment: overlayAlignment)
                    .offset(y: yOffset)
            }
            .frame(height: headerHeight)
            content()
        }
    }
}
