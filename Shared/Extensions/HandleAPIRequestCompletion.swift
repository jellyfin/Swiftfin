/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import Combine
import JellyfinAPI

func HandleAPIRequestCompletion(globalData: GlobalData, completion: Subscribers.Completion<Error>) {
    switch completion {
        case .finished:
            break
        case .failure(let error):
            if let err = error as? ErrorResponse {
                switch err {
                    case .error(401, _, _, _):
                        globalData.expiredCredentials = true
                    case .error:
                        globalData.networkError = true
                }
            }
            break
    }
}
