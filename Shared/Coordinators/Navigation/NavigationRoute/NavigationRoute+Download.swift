//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

extension NavigationRoute {

    @MainActor
    static var downloadList: NavigationRoute {
        let manager = Container.shared.downloadManager()
        let roots = manager.topLevel()
        let completed = roots.filter { manager.isFullyCompleted($0) }
        let completedIDs = Set(completed.map(\.id))
        let active = roots
            .filter { !completedIDs.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.state != rhs.state { return lhs.state < rhs.state }
                return lhs.createdAt < rhs.createdAt
            }

        let library = StaticLibrary(
            title: L10n.downloads,
            id: "downloads",
            elements: active + completed
        )

        return NavigationRoute(
            id: "downloadList"
        ) {
            PagingLibraryView(library: library)
        }
    }

    static func downloadItem(task: DownloadTask) -> NavigationRoute {
        NavigationRoute(
            id: "downloadItem"
        ) {
            DownloadItemView(task: task)
        }
    }
}
