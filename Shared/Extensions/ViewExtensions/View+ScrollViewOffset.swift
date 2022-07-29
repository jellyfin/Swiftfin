//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Introspect
import SwiftUI

struct ScrollViewOffsetModifier: ViewModifier {
    
    @Binding
    var scrollViewOffset: CGFloat
    
    private let coordinator: Coordinator?
    
    init(scrollViewOffset: Binding<CGFloat>) {
        self._scrollViewOffset = scrollViewOffset
        self.coordinator = Coordinator()
        self.coordinator?.parent = self
    }
    
    func body(content: Content) -> some View {
        content.introspectScrollView { scrollView in
            scrollView.delegate = coordinator
        }
    }
    
    private class Coordinator: NSObject, UIScrollViewDelegate {
        
        var parent: ScrollViewOffsetModifier?
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent?.scrollViewOffset = scrollView.contentOffset.y
        }
    }
}

extension View {
    func scrollViewOffset(_ scrollViewOffset: Binding<CGFloat>) -> some View {
        self.modifier(ScrollViewOffsetModifier(scrollViewOffset: scrollViewOffset))
    }
}
