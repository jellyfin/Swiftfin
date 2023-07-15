//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Introspect
import SwiftUI

struct RefreshableScrollView<Content: View>: View {

    let content: () -> Content
    let onRefresh: () -> Void

    private let refreshHelper = RefreshHelper()

    var body: some View {
        ScrollView(showsIndicators: false) {
            content()
        }
        .introspectScrollView { scrollView in
            let control = UIRefreshControl()

            refreshHelper.refreshControl = control
            refreshHelper.refreshAction = onRefresh

            control.addTarget(refreshHelper, action: #selector(RefreshHelper.didRefresh), for: .valueChanged)
            scrollView.refreshControl = control
        }
    }
}
