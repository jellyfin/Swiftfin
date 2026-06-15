//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import LocalAuthentication

extension AppPermission {

    static let deviceAuthentication = AppPermission(
        id: "device-authentication",
        displayTitle: L10n.deviceAuth,
        privacyDescriptionKey: "NSFaceIDUsageDescription",
        canRequest: {
            var error: NSError?
            return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        },
        request: { reason in
            let context = LAContext()
            var error: NSError?

            guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
                if let error {
                    throw error
                } else {
                    throw ErrorMessage(L10n.deviceAuthFailed)
                }
            }

            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ?? "")
            return .authorized
        },
        status: {
            var error: NSError?
            return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) ? .authorized : .denied
        }
    )
}
#endif
