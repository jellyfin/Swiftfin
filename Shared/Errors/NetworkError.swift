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

/**
 The implementation of the network errors here are a temporary measure.
 It is very repetitive, messy, and doesn't fulfill the entire specification of "error reporting".
 The specific kind of errors here should be created and surfaced from within JellyfinAPI on API calls.
 */

enum NetworkError: Error {

    /// For the case that the ErrorResponse object has a code of -1
    case URLError(response: ErrorResponse, displayMessage: String?, logConstructor: LogConstructor)

    /// For the case that the ErrorRespones object has a code of -2
    case HTTPURLError(response: ErrorResponse, displayMessage: String?, logConstructor: LogConstructor)

    /// For the case that the ErrorResponse object has a positive code
    case JellyfinError(response: ErrorResponse, displayMessage: String?, logConstructor: LogConstructor)

    var errorMessage: ErrorMessage {
        switch self {
        case .URLError(let response, let displayMessage, let logConstructor):
            return NetworkError.parseURLError(from: response, displayMessage: displayMessage, logConstructor: logConstructor)
        case .HTTPURLError(let response, let displayMessage, let logConstructor):
            return NetworkError.parseHTTPURLError(from: response, displayMessage: displayMessage, logConstructor: logConstructor)
        case .JellyfinError(let response, let displayMessage, let logConstructor):
            return NetworkError.parseJellyfinError(from: response, displayMessage: displayMessage, logConstructor: logConstructor)
        }
    }

    func logMessage() {
        let logConstructor = errorMessage.logConstructor
        let logFunction: (@autoclosure () -> String, String, String, String, UInt) -> Void

        switch logConstructor.level {
        case .trace:
            logFunction = LogManager.shared.log.trace
        case .debug:
            logFunction = LogManager.shared.log.debug
        case .information:
            logFunction = LogManager.shared.log.info
        case .warning:
            logFunction = LogManager.shared.log.warning
        case .error:
            logFunction = LogManager.shared.log.error
        case .critical:
            logFunction = LogManager.shared.log.critical
        case ._none:
            logFunction = LogManager.shared.log.debug
        }

        logFunction(logConstructor.message, logConstructor.tag, logConstructor.function, logConstructor.file, logConstructor.line)
    }

    private static func parseURLError(from response: ErrorResponse, displayMessage: String?, logConstructor: LogConstructor) -> ErrorMessage {

        let errorMessage: ErrorMessage
        var logMessage = "An error has occurred."
        var logConstructor = logConstructor

        switch response {
        case .error(_, _, _, let err):

            // These codes are currently referenced from:
            // https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes
            switch err._code {
            case -1001:
                logMessage = "Network timed out."
                logConstructor.message = logMessage
                errorMessage = ErrorMessage(code: err._code,
                                            title: "Timed Out",
                                            displayMessage: displayMessage,
                                            logConstructor: logConstructor)
            case -1004:
                logMessage = "Cannot connect to host."
                logConstructor.message = logMessage
                errorMessage = ErrorMessage(code: err._code,
                                            title: L10n.error,
                                            displayMessage: displayMessage,
                                            logConstructor: logConstructor)
            default:
                logConstructor.message = logMessage
                errorMessage = ErrorMessage(code: err._code,
                                            title: L10n.error,
                                            displayMessage: displayMessage,
                                            logConstructor: logConstructor)
            }
        }

        return errorMessage
    }

    private static func parseHTTPURLError(from response: ErrorResponse, displayMessage: String?, logConstructor: LogConstructor) -> ErrorMessage {

        let errorMessage: ErrorMessage
        let logMessage = "An HTTP URL error has occurred"
        var logConstructor = logConstructor

        // Not implemented as has not run into one of these errors as time of writing
        switch response {
        case .error:
            logConstructor.message = logMessage
            errorMessage = ErrorMessage(code: 0,
                                        title: L10n.error,
                                        displayMessage: displayMessage,
                                        logConstructor: logConstructor)
        }

        return errorMessage
    }

    private static func parseJellyfinError(from response: ErrorResponse, displayMessage: String?, logConstructor: LogConstructor) -> ErrorMessage {

        let errorMessage: ErrorMessage
        var logMessage = "An error has occurred."
        var logConstructor = logConstructor

        switch response {
        case .error(let code, _, _, _):

            // Generic HTTP status codes
            switch code {
            case 401:
                logMessage = "User is unauthorized."
                logConstructor.message = logMessage
                errorMessage = ErrorMessage(code: code,
                                            title: "Unauthorized",
                                            displayMessage: displayMessage,
                                            logConstructor: logConstructor)
            default:
                logConstructor.message = logMessage
                errorMessage = ErrorMessage(code: code,
                                            title: L10n.error,
                                            displayMessage: displayMessage,
                                            logConstructor: logConstructor)
            }
        }

        return errorMessage
    }
}
