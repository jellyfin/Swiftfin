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

class ViewModel: ObservableObject {

    @Published var isLoading = true
    @Published var errorMessage: ErrorMessage?

    let loading = ActivityIndicator()
    var cancellables = Set<AnyCancellable>()

    init() {
        loading.loading.assign(to: \.isLoading, on: self).store(in: &cancellables)
    }

    func handleAPIRequestError(displayMessage: String? = nil, logLevel: LogLevel = .error, tag: String = "", function: String = #function, file: String = #file, line: UInt = #line, completion: Subscribers.Completion<Error>) {
        switch completion {
        case .finished:
            break
        case .failure(let error):
            if let errorResponse = error as? ErrorResponse {

                let networkError: NetworkError
                let logConstructor = LogConstructor(message: "__NOTHING__", tag: tag, level: logLevel, function: function, file: file, line: line)

                switch errorResponse {
                case .error(-1, _, _, _):
                    networkError = .URLError(response: errorResponse, displayMessage: displayMessage, logConstructor: logConstructor)
                    // Use the errorResponse description for debugging, rather than the user-facing friendly description which may not be implemented
                    LogManager.shared.log.error("Request failed: URL request failed with error \(networkError.errorMessage.code): \(errorResponse.localizedDescription)")
                case .error(-2, _, _, _):
                    networkError = .HTTPURLError(response: errorResponse, displayMessage: displayMessage, logConstructor: logConstructor)
                    LogManager.shared.log.error("Request failed: HTTP URL request failed with description: \(errorResponse.localizedDescription)")
                default:
                    networkError = .JellyfinError(response: errorResponse, displayMessage: displayMessage, logConstructor: logConstructor)
                    // Able to use user-facing friendly description here since just HTTP status codes
                    LogManager.shared.log.error("Request failed: \(networkError.errorMessage.code) - \(networkError.errorMessage.title): \(networkError.errorMessage.logConstructor.message)\n\(error.localizedDescription)")
                }

                self.errorMessage = networkError.errorMessage

                networkError.logMessage()
            }
        }
    }
}
