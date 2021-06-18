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
import ActivityIndicator
import JellyfinAPI

typealias ErrorMessage = String

extension ErrorMessage: Identifiable {
    public var id: String {
        self
    }
}

class ViewModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()
    @Published
    var isLoading = true
    let loading = ActivityIndicator()
    @Published
    var errorMessage: ErrorMessage?

    init() {
        loading.loading.assign(to: \.isLoading, on: self).store(in: &cancellables)
    }

    func handleAPIRequestCompletion(completion: Subscribers.Completion<Error>) {
        switch completion {
            case .finished:
                break
            case .failure(let error):
                if let err = error as? ErrorResponse {
                    switch err {
                        case .error(401, _, _, _):
                            self.errorMessage = err.localizedDescription
                            SessionManager.current.logout()
                        case .error:
                            self.errorMessage = err.localizedDescription
                    }
                }
                break
        }
    }
}
