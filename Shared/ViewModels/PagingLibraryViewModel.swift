//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

class PagingLibraryViewModel: ViewModel {

    @Published
    var items: [BaseItemDto] = []

    var currentPage = 0
    var hasNextPage = true

    func requestNextPage() {
        guard hasNextPage else { return }
        currentPage += 1
        _requestNextPage()
    }

    func _requestNextPage() {}
}
