//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

class RemoteImageViewModel: PagingLibraryViewModel {
    
    @Published
    var images: [RemoteImageInfo] = []
    
    let item: BaseItemDto
    let imageType: ImageType
    
    init(item: BaseItemDto, imageType: ImageType) {
        self.item = item
        self.imageType = imageType
        super.init()
        
        requestNextPage()
    }
    
    override func _requestNextPage() {
        guard let itemID = item.id else { return }
        
        RemoteImageAPI.getRemoteImages(
            itemId: itemID,
            type: imageType,
            startIndex: currentPage,
            limit: 30
        )
        .sink { completion in
            self.handleAPIRequestError(completion: completion)
        } receiveValue: { result in
            self.images = result.images ?? []
        }
        .store(in: &cancellables)
    }
}
