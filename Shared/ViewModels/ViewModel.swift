//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import ActivityIndicator
import Combine
import Factory
import Foundation
import JellyfinAPI

class ViewModel: ObservableObject {

    @Injected(LogManager.service)
    var logger
    @Published
    var isLoading = false
    @Published
    var errorMessage: ErrorMessage?

    let loading = ActivityIndicator()
    var cancellables = Set<AnyCancellable>()

    init() {
        loading.loading.assign(to: \.isLoading, on: self).store(in: &cancellables)
    }

    func handleAPIRequestError(displayMessage: String? = nil, completion: Subscribers.Completion<Error>) {
        switch completion {
        case .finished:
            self.errorMessage = nil
        case let .failure(error):
            switch error {
            case is ErrorResponse:
                let networkError: NetworkError
                let errorResponse = error as! ErrorResponse

                switch errorResponse {
                case .error(-1, _, _, _):
                    networkError = .URLError(response: errorResponse, displayMessage: displayMessage)
                    // Use the errorResponse description for debugging, rather than the user-facing friendly description which may not be implemented
                    logger
                        .error(
                            "Request failed: URL request failed with error \(networkError.errorMessage.code): \(errorResponse.localizedDescription)"
                        )
                case .error(-2, _, _, _):
                    networkError = .HTTPURLError(response: errorResponse, displayMessage: displayMessage)
                    logger
                        .error("Request failed: HTTP URL request failed with description: \(errorResponse.localizedDescription)")

                case let .error(_, _, _, baseError as DecodingError):
                    networkError = .JellyfinError(response: errorResponse, displayMessage: displayMessage)
                    if case let .dataCorrupted(decodeContext) = baseError {
                        let codingPath = decodeContext.codingPath.map(\.stringValue).joined(separator: ",")
                        let underlyingError = decodeContext.debugDescription
                        logger
                            .error(
                                "Request failed: JSON Decoding failed: Underlying Error: \(underlyingError) - Coding Path: [\(codingPath)]"
                            )
                    } else {
                        logger
                            .error("Request failed: JSON Decoding failed!")
                    }

                default:
                    networkError = .JellyfinError(response: errorResponse, displayMessage: displayMessage)
                    // Able to use user-facing friendly description here since just HTTP status codes
                    logger
                        .error(
                            "Request failed: \(networkError.errorMessage.code) - \(networkError.errorMessage.title): \(networkError.errorMessage.message)\n\(error.localizedDescription)"
                        )
                }

                self.errorMessage = networkError.errorMessage

            case is SwiftfinStore.Error:
                let swiftfinError = error as! SwiftfinStore.Error
                let errorMessage = ErrorMessage(
                    code: ErrorMessage.noShowErrorCode,
                    title: swiftfinError.title,
                    message: swiftfinError.errorDescription ?? ""
                )
                self.errorMessage = errorMessage
                logger.error("Request failed: \(swiftfinError.errorDescription ?? "")")

            default:
                let genericErrorMessage = ErrorMessage(
                    code: ErrorMessage.noShowErrorCode,
                    title: "Generic Error",
                    message: error.localizedDescription
                )
                self.errorMessage = genericErrorMessage
                logger.error("Request failed: Generic error - \(error.localizedDescription)")
            }
        }
    }
}
