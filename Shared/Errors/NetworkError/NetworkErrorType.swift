//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

// TODO: Localize

enum NetworkErrorType: String, Hashable, Displayable, SystemImageable {
    case client
    case server
    case network
    case data
    case unknown

    var displayTitle: String {
        switch self {
        case .client:
            return "Client Error"
        case .server:
            return "Server Error"
        case .network:
            return "Network Error"
        case .data:
            return "Data Error"
        case .unknown:
            return L10n.unknownError
        }
    }

    var systemImage: String {
        switch self {
        case .client:
            #if os(iOS)
            return "ipad.landscape.and.iphone.slash"
            #elseif os(tvOS)
            return "tv.slash"
            #elseif os(macOS)
            return "macbook.slash"
            #endif
        case .server:
            return "square.3.layers.3d.slash"
        case .network:
            return "network.slash"
        case .data:
            return "square.3.layers.3d.down.right.slash"
        case .unknown:
            return "xmark.circle"
        }
    }

    init(_ statusCode: Int) {
        switch statusCode {
        case 400 ... 499:
            self = .client
        case 500 ... 599:
            self = .server
        case 1000 ... 1999:
            self = .network
        case 2000 ... 2999:
            self = .data
        default:
            self = .unknown
        }
    }
}
