//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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

struct SplitContentView: View {

    @ObservedObject
    private var proxy: SplitContentViewProxy

    private var content: () -> any View
    private var splitContent: () -> any View
    private var splitContentWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {

            content()
                .eraseToAnyView()
                .frame(maxWidth: .infinity)

            if proxy.isPresentingSplitView {
                splitContent()
                    .eraseToAnyView()
                    .transition(.move(edge: .bottom))
                    .frame(width: splitContentWidth)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: proxy.isPresentingSplitView)
    }
}

extension SplitContentView {

    init(splitContentWidth: CGFloat = 400) {
        self.init(
            proxy: .init(),
            content: { EmptyView() },
            splitContent: { EmptyView() },
            splitContentWidth: splitContentWidth
        )
    }

    func proxy(_ proxy: SplitContentViewProxy) -> Self {
        copy(modifying: \.proxy, with: proxy)
    }

    func content(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    func splitContent(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.splitContent, with: content)
    }
}
