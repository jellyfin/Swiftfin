//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

final class DownloadListViewModel: ViewModel {
    
    @Published
    var downloadingItems: [OfflineItem] = []
    @Published
    var offlineItems: [OfflineItem] = []
    
    override init() {
        super.init()
        
        refresh()
        
        Notifications[.didAddDownload].subscribe(self, selector: #selector(refresh))
        Notifications[.didDeleteOfflineItem].subscribe(self, selector: #selector(refresh))
    }
    
    @objc private func refresh() {
        downloadingItems = Array(DownloadManager.main.downloadingItems)
        offlineItems = DownloadManager.main.getOfflineItems()
    }
}
