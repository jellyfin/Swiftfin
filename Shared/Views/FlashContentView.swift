//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FlashContentView: View {

    @ObservedObject
    var proxy: FlashContentProxy

    var body: some View {
        Group {
            if let currentView = proxy.currentView {
                currentView
            } else {
                EmptyView()
            }
        }
        .opacity(proxy.isShowing ? 1 : 0)
        .animation(.linear(duration: 0.1), value: proxy.isShowing)
    }
}
