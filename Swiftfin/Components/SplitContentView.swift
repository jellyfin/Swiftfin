//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

class SplitContentViewProxy: ObservableObject {
    
    @Published
    private(set) var isPresentingSplitView: Bool = false
    
    func present() {
        isPresentingSplitView = true
    }
    
    func hide() {
        isPresentingSplitView = false
    }
}

struct SplitContentView<Content: View, SplitContent: View>: View {
    
    @ObservedObject
    private var proxy: SplitContentViewProxy
    
    private var content: () -> Content
    private var splitContent: () -> SplitContent
    private var splitContentWidth: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            
            content()
                .frame(maxWidth: .infinity)
            
            if proxy.isPresentingSplitView {
                splitContent()
                    .transition(.move(edge: .bottom))
                    .frame(width: splitContentWidth)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: proxy.isPresentingSplitView)
    }
}

extension SplitContentView where Content == EmptyView, SplitContent == EmptyView {
    init() {
        self.init(
            proxy: .init(),
            content: { EmptyView() },
            splitContent: { EmptyView() },
            splitContentWidth: 400
        )
    }
}

extension SplitContentView {
    
    func proxy(_ proxy:  SplitContentViewProxy) -> Self {
        copy(modifying: \.proxy, with: proxy)
    }
    
    func content<C: View>(@ViewBuilder _ content: @escaping () -> C) -> SplitContentView<C, SplitContent> {
        .init(
            proxy: proxy,
            content: content,
            splitContent: splitContent,
            splitContentWidth: splitContentWidth
        )
    }
    
    func splitContent<C: View>(@ViewBuilder _ splitContent: @escaping () -> C) -> SplitContentView<Content, C> {
        .init(
            proxy: proxy,
            content: content,
            splitContent: splitContent,
            splitContentWidth: splitContentWidth
        )
    }
}
