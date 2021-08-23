//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import JellyfinAPI

class ServerDetailViewModel: ViewModel {

    func refreshServerLibrary() {
        LibraryAPI.refreshLibrary()
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(completion: completion)
            }, receiveValue: {
                LogManager.shared.log.debug("Refreshed server library successfully")
            })
            .store(in: &cancellables)
    }
}
