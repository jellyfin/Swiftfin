//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol HorizontalSizeClassView: View {

    associatedtype CompactBody: View
    associatedtype RegularBody: View

    @ViewBuilder @MainActor
    var compact: CompactBody { get }
    @ViewBuilder @MainActor
    var regular: RegularBody { get }
}

extension HorizontalSizeClassView where Body == _HorizontalSizeClassView<Self> {
    var body: _HorizontalSizeClassView<Self> {
        _HorizontalSizeClassView(content: self)
    }
}

struct _HorizontalSizeClassView<Content: HorizontalSizeClassView>: View {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    let content: Content

    var body: some View {
        if horizontalSizeClass == .compact {
            content.compact
        } else {
            content.regular
        }
    }
}
