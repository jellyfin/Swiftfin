//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct ScrollViewOffsetModifier: ViewModifier {

    @StateObject
    private var scrollViewDelegate: ScrollViewDelegate

    init(scrollViewOffset: Binding<CGFloat>) {
        self._scrollViewDelegate = StateObject(wrappedValue: ScrollViewDelegate(scrollViewOffset: scrollViewOffset))
    }

    func body(content: Content) -> some View {
        content.introspect(
            .scrollView,
            on: .iOS(.v15...),
            .tvOS(.v15...)
        ) { scrollView in
            scrollView.delegate = scrollViewDelegate
        }
    }

    private class ScrollViewDelegate: NSObject, ObservableObject, UIScrollViewDelegate {

        let scrollViewOffset: Binding<CGFloat>

        init(scrollViewOffset: Binding<CGFloat>) {
            self.scrollViewOffset = scrollViewOffset
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollViewOffset.wrappedValue = scrollView.contentOffset.y
        }
    }
}
