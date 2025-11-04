//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: Localize
// TODO: Move to SDK?

enum NetworkError: LocalizedError, Equatable, Hashable, Displayable {

    // MARK: Client Errors (4xx)

    /// 400 Bad Request - The request was malformed or invalid
    case badRequest
    /// 401 Unauthorized - Authentication is required or has failed
    case unauthorized
    /// 403 Forbidden - The server understood the request but refuses to authorize it
    case forbidden
    /// 404 Not Found - The requested resource could not be found
    case notFound
    /// 405 Method Not Allowed - The HTTP method is not supported for this resource
    case methodNotAllowed
    /// 406 Not Acceptable - The server cannot produce a response matching the accept headers
    case notAcceptable
    /// 408 Request Timeout - The server timed out waiting for the request
    case requestTimeout
    /// 409 Conflict - The request conflicts with the current state of the server
    case conflict
    /// 410 Gone - The requested resource is no longer available
    case gone
    /// 413 Payload Too Large - The request entity is larger than limits defined by server
    case payloadTooLarge
    /// 415 Unsupported Media Type - The media format is not supported
    case unsupportedMediaType
    /// 422 Unprocessable Entity - The request was well-formed but contains semantic errors
    case unprocessableEntity
    /// 429 Too Many Requests - Rate limit exceeded
    case tooManyRequests
    /// Other 4xx client error
    case clientError(statusCode: Int)

    // MARK: Server Errors (5xx)

    /// 500 Internal Server Error - Generic server error
    case internalServerError
    /// 501 Not Implemented - The server does not support the functionality required
    case notImplemented
    /// 502 Bad Gateway - The server received an invalid response from an upstream server
    case badGateway
    /// 503 Service Unavailable - The server is temporarily unavailable
    case serviceUnavailable(retrySeconds: Int)
    /// 504 Gateway Timeout - The server did not receive a timely response from an upstream server
    case gatewayTimeout
    /// 505 HTTP Version Not Supported - The HTTP version is not supported
    case httpVersionNotSupported
    /// Other 5xx server error
    case serverError(statusCode: Int)

    // MARK: Network/Connection Errors

    /// No internet connection available
    case noConnection
    /// The connection was lost during the request
    case connectionLost
    /// DNS lookup failed
    case dnsLookupFailed
    /// Could not connect to the server
    case cannotConnectToHost
    /// The connection timed out
    case timedOut
    /// SSL/TLS error occurred
    case secureConnectionFailed
    /// The server's SSL certificate is invalid
    case serverCertificateInvalid
    /// The request was cancelled
    case cancelled

    // MARK: Data Errors

    /// Response data could not be decoded
    case decodingFailed
    /// Response data could not be encoded
    case encodingFailed
    /// The response was invalid or unexpected
    case invalidResponse

    // MARK: Other

    /// An unknown or unhandled error occurred
    case unknown

    // MARK: - Properties

    /// The HTTP status code associated with this error source, if applicable
    var statusCode: Int? {
        switch self {
        case .badRequest:
            return 400
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .methodNotAllowed:
            return 405
        case .notAcceptable:
            return 406
        case .requestTimeout:
            return 408
        case .conflict:
            return 409
        case .gone:
            return 410
        case .payloadTooLarge:
            return 413
        case .unsupportedMediaType:
            return 415
        case .unprocessableEntity:
            return 422
        case .tooManyRequests:
            return 429
        case let .clientError(code):
            return code
        case .internalServerError:
            return 500
        case .notImplemented:
            return 501
        case .badGateway:
            return 502
        case .serviceUnavailable:
            return 503
        case .gatewayTimeout:
            return 504
        case .httpVersionNotSupported:
            return 505
        case let .serverError(code):
            return code
        default:
            return nil
        }
    }

    var displayTitle: String {
        switch self {
        case .badRequest:
            return "Invalid Request"
        case .unauthorized:
            return "Authentication Required"
        case .forbidden:
            return "Access Denied"
        case .notFound:
            return "Not Found"
        case .methodNotAllowed:
            return "Method Not Allowed"
        case .notAcceptable:
            return "Not Acceptable"
        case .requestTimeout:
            return "Request Timeout"
        case .conflict:
            return "Conflict"
        case .gone:
            return "Gone"
        case .payloadTooLarge:
            return "File Too Large"
        case .unsupportedMediaType:
            return "Unsupported Format"
        case .unprocessableEntity:
            return "Invalid Data"
        case .tooManyRequests:
            return "Too Many Requests"
        case let .clientError(code):
            return "Client Error (\(code))"
        case .internalServerError:
            return "Server Error"
        case .notImplemented:
            return "Not Implemented"
        case .badGateway:
            return "Bad Gateway"
        case .serviceUnavailable:
            return "Service Unavailable"
        case .gatewayTimeout:
            return "Gateway Timeout"
        case .httpVersionNotSupported:
            return "HTTP Version Not Supported"
        case let .serverError(code):
            return "Server Error (\(code))"
        case .noConnection:
            return "No Connection"
        case .connectionLost:
            return "Connection Lost"
        case .dnsLookupFailed:
            return "DNS Lookup Failed"
        case .cannotConnectToHost:
            return "Cannot Connect"
        case .timedOut:
            return "Timed Out"
        case .secureConnectionFailed:
            return "Secure Connection Failed"
        case .serverCertificateInvalid:
            return "Invalid Certificate"
        case .cancelled:
            return "Cancelled"
        case .decodingFailed:
            return "Decoding Failed"
        case .encodingFailed:
            return "Encoding Failed"
        case .invalidResponse:
            return "Invalid Response"
        case .unknown:
            return L10n.unknownError
        }
    }

    var type: NetworkErrorType {
        guard let statusCode else { return .unknown }
        return NetworkErrorType(statusCode)
    }

    var isRetryable: Bool {
        type == .network || type == .server
    }

    // MARK: - LocalizedError

    var errorDescription: String? {
        displayTitle
    }

    var failureReason: String? {
        displayTitle
    }

    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Please refresh your account token to continue."
        case .forbidden:
            return "Contact the Jellyfin server administrator if you believe you should have access."
        case .notFound:
            return "The item may have been deleted or moved."
        case .tooManyRequests:
            return "Please wait a moment before trying again."
        case .noConnection:
            return "Check your internet connection and try again."
        case .dnsLookupFailed, .cannotConnectToHost:
            return "Verify the server address and your network connection."
        case .timedOut, .requestTimeout:
            return "Check your connection and try again."
        case .serverCertificateInvalid, .secureConnectionFailed:
            return "Verify the server's SSL certificate or contact your administrator."
        case let .serviceUnavailable(seconds):
            return "The server may be down for maintenance. Try again in \(seconds) seconds."
        case .internalServerError, .serverError, .badGateway, .gatewayTimeout:
            return "Try again later or contact the Jellyfin server administrator if the problem persists."
        default:
            return nil
        }
    }
}

// MARK: - Initializers

extension NetworkError {

    /// Initialize from an HTTP status code
    init(_ statusCode: Int, retrySeconds: Int? = nil) {
        switch statusCode {
        case 400:
            self = .badRequest
        case 401:
            self = .unauthorized
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        case 405:
            self = .methodNotAllowed
        case 406:
            self = .notAcceptable
        case 408:
            self = .requestTimeout
        case 409:
            self = .conflict
        case 410:
            self = .gone
        case 413:
            self = .payloadTooLarge
        case 415:
            self = .unsupportedMediaType
        case 422:
            self = .unprocessableEntity
        case 429:
            self = .tooManyRequests
        case 400 ... 499:
            self = .clientError(statusCode: statusCode)
        case 500:
            self = .internalServerError
        case 501:
            self = .notImplemented
        case 502:
            self = .badGateway
        case 503:
            self = .serviceUnavailable(retrySeconds: retrySeconds ?? 999)
        case 504:
            self = .gatewayTimeout
        case 505:
            self = .httpVersionNotSupported
        case 500 ... 599:
            self = .serverError(statusCode: statusCode)
        default:
            self = .unknown
        }
    }

    init(_ urlError: URLError) {
        switch urlError.code {
        case .notConnectedToInternet:
            self = .noConnection
        case .networkConnectionLost:
            self = .connectionLost
        case .cannotFindHost, .dnsLookupFailed:
            self = .dnsLookupFailed
        case .cannotConnectToHost:
            self = .cannotConnectToHost
        case .timedOut:
            self = .timedOut
        case .secureConnectionFailed:
            self = .secureConnectionFailed
        case .serverCertificateHasBadDate, .serverCertificateUntrusted,
             .serverCertificateHasUnknownRoot, .serverCertificateNotYetValid:
            self = .serverCertificateInvalid
        case .cancelled:
            self = .cancelled
        case .badServerResponse:
            self = .invalidResponse
        default:
            self = .unknown
        }
    }
}

// TODO: Remove when complete

// This is only kept as reference until more strongly-typed errors are implemented.

// enum NetworkError: Error {
//
//    /// For the case that the ErrorResponse object has a code of -1
//    case URLError(response: ErrorResponse, displayMessage: String?)
//
//    /// For the case that the ErrorRespones object has a code of -2
//    case HTTPURLError(response: ErrorResponse, displayMessage: String?)
//
//    /// For the case that the ErrorResponse object has a positive code
//    case JellyfinError(response: ErrorResponse, displayMessage: String?)
//
//    var errorMessage: ErrorMessage {
//        switch self {
//        case let .URLError(response, displayMessage):
//            return NetworkError.parseURLError(from: response, displayMessage: displayMessage)
//        case let .HTTPURLError(response, displayMessage):
//            return NetworkError.parseHTTPURLError(from: response, displayMessage: displayMessage)
//        case let .JellyfinError(response, displayMessage):
//            return NetworkError.parseJellyfinError(from: response, displayMessage: displayMessage)
//        }
//    }
//
//    private static func parseURLError(from response: ErrorResponse, displayMessage: String?) -> ErrorMessage {
//        let errorMessage: ErrorMessage
//
//        switch response {
//        case let .error(_, _, _, err):
//
//            // Code references:
//            // https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes
//            switch err._code {
//            case -1001:
//                errorMessage = ErrorMessage(
//                    code: err._code,
//                    title: L10n.error,
//                    message: L10n.networkTimedOut
//                )
//            case -1003:
//                errorMessage = ErrorMessage(
//                    code: err._code,
//                    title: L10n.error,
//                    message: L10n.unableToFindHost
//                )
//            case -1004:
//                errorMessage = ErrorMessage(
//                    code: err._code,
//                    title: L10n.error,
//                    message: L10n.cannotConnectToHost
//                )
//            default:
//                errorMessage = ErrorMessage(
//                    code: err._code,
//                    title: L10n.error,
//                    message: L10n.unknownError
//                )
//            }
//        }
//
//        return errorMessage
//    }
//
//    private static func parseHTTPURLError(from response: ErrorResponse, displayMessage: String?) -> ErrorMessage {
//        let errorMessage: ErrorMessage
//
//        // Not implemented as has not run into one of these errors as time of writing
//        switch response {
//        case .error:
//            errorMessage = ErrorMessage(
//                code: 0,
//                title: L10n.error,
//                message: "An HTTP URL error has occurred"
//            )
//        }
//
//        return errorMessage
//    }
//
//    private static func parseJellyfinError(from response: ErrorResponse, displayMessage: String?) -> ErrorMessage {
//        let errorMessage: ErrorMessage
//
//        switch response {
//        case let .error(code, _, _, _):
//
//            // Generic HTTP status codes
//            switch code {
//            case 401:
//                errorMessage = ErrorMessage(
//                    code: code,
//                    title: L10n.unauthorized,
//                    message: L10n.unauthorizedUser
//                )
//            default:
//                errorMessage = ErrorMessage(
//                    code: code,
//                    title: L10n.error,
//                    message: displayMessage ?? L10n.unknownError
//                )
//            }
//        }
//
//        return errorMessage
//    }
// }
