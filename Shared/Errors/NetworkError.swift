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

enum NetworkError: Error {
    
    /// For the case that the ErrorResponse object has a code of -1
    case URLError(response: ErrorResponse, displayMessage: String?, logLevel: LogLevel, tag: String?)
    
    /// For the case that the ErrorRespones object has a code of -2
    case HTTPURLError(response: ErrorResponse, displayMessage: String?, logLevel: LogLevel, tag: String?)
    
    /// For the case that the ErrorResponse object has a positive code
    case JellyfinError(response: ErrorResponse, displayMessage: String?, logLevel: LogLevel, tag: String?)
    
    var errorMessage: ErrorMessage {
        switch self {
        case .URLError(response: let response, displayMessage: let displayMessage, let logLevel, let tag):
            return NetworkError.parseURLError(from: response, displayMessage: displayMessage, logLevel: logLevel, logTag: tag)
        case .HTTPURLError(response: let response, displayMessage: let displayMessage, let logLevel, let tag):
            return NetworkError.parseHTTPURLError(from: response, displayMessage: displayMessage, logLevel: logLevel, logTag: tag)
        case .JellyfinError(response: let response, displayMessage: let displayMessage, let logLevel, let tag):
            return NetworkError.parseJellyfinError(from: response, displayMessage: displayMessage, logLevel: logLevel, logTag: tag)
        }
    }
    
    func logMessage() {
        let errorMessage = self.errorMessage
        let logFunction: (@autoclosure () -> String, String, String, String, UInt) -> Void
        
        switch errorMessage.logLevel {
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
        
        logFunction(errorMessage.logMessage, "", "", "", 0)
    }
    
    private static func parseURLError(from response: ErrorResponse, displayMessage: String?, logLevel: LogLevel, logTag: String?) -> ErrorMessage {
        
        let errorMessage: ErrorMessage
        var logMessage = "An error has occurred."
        
        switch response {
        case .error(_, _, _, let err):
            
            // These codes are currently referenced from:
            // https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes
            switch err._code {
            case -1001:
                logMessage = "Network timed out."
                errorMessage = ErrorMessage(code: err._code,
                                            title: "Timed Out",
                                            displayMessage: displayMessage,
                                            logMessage: logMessage,
                                            logLevel: logLevel,
                                            logTag: logTag)
            case -1004:
                logMessage = "Cannot connect to host."
                errorMessage = ErrorMessage(code: err._code,
                                            title: "Error",
                                            displayMessage: displayMessage,
                                            logMessage: logMessage,
                                            logLevel: logLevel,
                                            logTag: logTag)
            default:
                errorMessage = ErrorMessage(code: err._code,
                                            title: "Error",
                                            displayMessage: displayMessage,
                                            logMessage: logMessage,
                                            logLevel: logLevel,
                                            logTag: logTag)
            }
        }
        
        return errorMessage
    }
    
    private static func parseHTTPURLError(from response: ErrorResponse, displayMessage: String?, logLevel: LogLevel, logTag: String?) -> ErrorMessage {
        
        let errorMessage: ErrorMessage
        let logMessage = "An HTTP URL error has occurred"
        
        // Not implemented as has not run into one of these errors as time of writing
        switch response {
        case .error(_, _, _, _):
            errorMessage = ErrorMessage(code: 0,
                                        title: "Error",
                                        displayMessage: displayMessage,
                                        logMessage: logMessage,
                                        logLevel: logLevel,
                                        logTag: logTag)
        }
        
        return errorMessage
    }
    
    private static func parseJellyfinError(from response: ErrorResponse, displayMessage: String?, logLevel: LogLevel, logTag: String?) -> ErrorMessage {
        
        let errorMessage: ErrorMessage
        var logMessage = "An error has occurred."
        
        switch response {
        case .error(let code, _, _, _):
            
            // Generic HTTP status codes
            switch code {
            case 401:
                logMessage = "User is unauthorized."
                errorMessage = ErrorMessage(code: code,
                                            title: "Unauthorized",
                                            displayMessage: displayMessage,
                                            logMessage: logMessage,
                                            logLevel: logLevel,
                                            logTag: logTag)
            default:
                errorMessage = ErrorMessage(code: code,
                                            title: "Error",
                                            displayMessage: displayMessage,
                                            logMessage: logMessage,
                                            logLevel: logLevel,
                                            logTag: logTag)
            }
        }
        
        return errorMessage
    }
}
