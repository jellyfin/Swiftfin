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
import UIKit

class PagingLibraryViewModel: ViewModel {

    @Default(.Customization.Library.gridPosterType)
    private var libraryGridPosterType

    @Published
    var items: [BaseItemDto] = []

    var currentPage = 0
    var hasNextPage = true

    var pageItemSize: Int {
        let height = libraryGridPosterType == .portrait ? libraryGridPosterType.width * 1.5 : libraryGridPosterType.width / 1.77
        return UIScreen.main.maxChildren(width: libraryGridPosterType.width, height: height)
    }

    func requestNextPage() {
        guard hasNextPage else { return }
        currentPage += 1
        _requestNextPage()
    }

    func _requestNextPage() {}
}
