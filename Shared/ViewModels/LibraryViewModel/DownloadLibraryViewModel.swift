//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Get
import JellyfinAPI
import OrderedCollections
import SwiftUI

final class DownloadLibraryViewModel: PagingLibraryViewModel<BaseItemDto>, Identifiable {

    // TODO: do we need observed object here?
    @Injected(Container.downloadManager)
    private var downloadManager: DownloadManager

    // MARK: get

    override func get(page: Int) async throws -> [BaseItemDto] {
        // 1 - only care to keep collections that hold valid items
        // 2 - if parent is type `folder`, then we are in a folder-view
        //     context so change `collectionFolder` types to `folder`
        //     for better view handling
        let items = (downloadManager.downloads)
            .filter { download in
                if let collectionType = download.item.collectionType {
                    return ["movies", "tvshows", "mixed", "boxsets"].contains(collectionType)
                }

                return true
            }
            .map { download in
                if parent?.libraryType == .folder, download.item.type == .collectionFolder {
                    return download.mutating(\.item.type, with: .folder).item
                }

                return download.item
            }

        return items
    }
}
