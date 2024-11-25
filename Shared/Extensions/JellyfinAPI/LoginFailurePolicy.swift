//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

enum LoginFailurePolicy: Int, Displayable, CaseIterable {

    case unlimited = -1
    case userDefault = 3
    case adminDefault = 5
    case custom = 0 // Default to 0

    // MARK: - Display Title

    var displayTitle: String {
        switch self {
        case .unlimited:
            return L10n.unlimited
        case .userDefault, .adminDefault:
            return L10n.default
        case .custom:
            return L10n.custom
        }
    }

    // MARK: - Get Policy from a Bitrate (Int)

    static func from(rawValue: Int, isAdministrator: Bool) -> LoginFailurePolicy {
        let policy = LoginFailurePolicy(rawValue: rawValue)

        if isAdministrator && policy == .userDefault {
            return .custom
        } else if !isAdministrator && policy == .adminDefault {
            return .custom
        } else {
            return policy ?? .custom
        }
    }
}
