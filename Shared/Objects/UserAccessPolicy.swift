//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

// TODO: require remote sign in every time
//       - actually found to be a bit difficult?
// TODO: rename to not confuse with server access/UserDto

enum UserAccessPolicy: String, CaseIterable, Codable, Displayable {

    case none
    case requireDeviceAuthentication
    case requirePin

    var displayTitle: String {
        switch self {
        case .none:
            L10n.none
        case .requireDeviceAuthentication:
            L10n.deviceAuth
        case .requirePin:
            L10n.pin
        }
    }

    func createReason(user: UserState) -> String? {
        switch self {
        case .none: nil
        case .requireDeviceAuthentication:
            L10n.requireDeviceAuthForUser(user.username)
        case .requirePin:
            L10n.createPinForUser(user.username)
        }
    }

    func authenticateReason(user: UserState) -> String? {
        switch self {
        case .none: nil
        case .requireDeviceAuthentication:
            L10n.requireDeviceAuthForUser(user.username)
        case .requirePin:
            L10n.enterPinForUser(user.username)
        }
    }
}

protocol EvaluatedLocalUserAccessPolicy {}

struct EmptyEvaluatedUserAccessPolicy: EvaluatedLocalUserAccessPolicy {}

struct PinEvaluatedUserAccessPolicy: EvaluatedLocalUserAccessPolicy {
    let pin: String
    let pinHint: String?
}
