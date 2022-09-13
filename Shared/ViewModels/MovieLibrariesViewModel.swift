//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI
import UIKit

final class MoviesLibraryViewModel: PagingLibraryViewModel {
    
    @Default(.Customization.Library.gridPosterType)
    private var libraryGridPosterType
    
    override init() {
        super.init()
        
        _requestNextPage()
    }
    
    private var pageItemSize: Int {
        let height = libraryGridPosterType == .portrait ? libraryGridPosterType.width * 1.5 : libraryGridPosterType.width / 1.77
        return UIScreen.main.maxChildren(width: libraryGridPosterType.width, height: height)
    }

    override func _requestNextPage() {
        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            startIndex: currentPage * pageItemSize,
            limit: pageItemSize,
            recursive: true,
            sortOrder: [.ascending],
            fields: ItemFields.allCases,
            includeItemTypes: [.movie],
            sortBy: [SortBy.name.rawValue],
            enableUserData: true,
            enableImages: true
        )
        .trackActivity(loading)
        .sink { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        } receiveValue: { [weak self] response in
            guard let items = response.items else { return }
            guard !items.isEmpty else {
                self?.hasNextPage = false
                return
            }
            
            self?.items.append(contentsOf: items)
        }
        .store(in: &cancellables)
    }
}
