//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

class DownloadListViewModel: ViewModel {

    @Injected(Container.downloadManager)
    private var downloadManager

    @Published
    var items: [DownloadEntity] = []

    override init() {
        super.init()

        items = downloadManager.downloads
        // TODO: check if this works properly
//        _ = downloadManager.objectWillChange.sink(receiveValue: refresh)
    }

    func refresh() {
        items = downloadManager.downloads
    }

    func remove(task: DownloadEntity) {
        downloadManager.remove(task: task)
        items.removeAll(where: { $0.item == task.item })
    }
}
