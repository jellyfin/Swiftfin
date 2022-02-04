//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import ActivityIndicator
import Combine
import Foundation
import JellyfinAPI

final class OfflineHomeViewModel: ViewModel {
    
    @Published
    var offlineItems: [OfflineItem] = []
    
    override init() {
        super.init()
        
        self.offlineItems = DownloadManager.main.getOfflineItems()
        
        Notifications[.didDeleteOfflineItem].subscribe(self, selector: #selector(didDeleteItem))
    }
    
    @objc private func didDeleteItem() {
        self.offlineItems = DownloadManager.main.getOfflineItems()
    }
}
