//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Introspect
import SwiftUI

struct ScrollViewOffsetModifier: ViewModifier {

    @Binding
    var scrollViewOffset: CGFloat

    private let scrollViewDelegate: ScrollViewDelegate?

    init(scrollViewOffset: Binding<CGFloat>) {
        self._scrollViewOffset = scrollViewOffset
        self.scrollViewDelegate = ScrollViewDelegate()
        self.scrollViewDelegate?.parent = self
    }

    func body(content: Content) -> some View {
        content.introspectScrollView { scrollView in
            scrollView.delegate = scrollViewDelegate
        }
    }

    private class ScrollViewDelegate: NSObject, UIScrollViewDelegate {

        var parent: ScrollViewOffsetModifier?

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent?._scrollViewOffset.wrappedValue = scrollView.contentOffset.y
        }
    }
}
