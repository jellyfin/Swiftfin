//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import Foundation
import JellyfinAPI

final class LatestMediaViewModel: ViewModel {

    @Published var items = [BaseItemDto]()
    
    let library: BaseItemDto

    init(library: BaseItemDto) {
        self.library = library
        super.init()

        requestLatestMedia()
    }

    func requestLatestMedia() {
        LogManager.shared.log.debug("Requesting latest media for user id \(SessionManager.main.currentLogin.user.id)")
        UserLibraryAPI.getLatestMedia(userId: SessionManager.main.currentLogin.user.id,
                                      parentId: library.id ?? "",
                                      fields: [
                                        .primaryImageAspectRatio,
                                        .seriesPrimaryImage,
                                        .seasonUserData,
                                        .overview,
                                        .genres,
                                        .people
                                      ],
                                      includeItemTypes: ["Series", "Movie"],
                                      enableUserData: true, limit: 12)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.items = response
                LogManager.shared.log.debug("Retrieved \(String(self?.items.count ?? 0)) items")
            })
            .store(in: &cancellables)
    }
}
