//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension NavigationRoute {

    static let downloadList = NavigationRoute(
        id: "downloadList"
    ) {
        #if os(iOS)
        DownloadListView(viewModel: .init())
        #else
        EmptyView()
        #endif
    }

    #if os(iOS)
    static func downloadTask(downloadTask: DownloadTask) -> NavigationRoute {
        NavigationRoute(
            id: "downloadTask",
            style: .sheet
        ) {
            DownloadTaskView(downloadTask: downloadTask)
        }
    }
    #endif
}
