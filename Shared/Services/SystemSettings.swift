//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Accessibility
import UIKit

@MainActor
enum SystemSettings {

    case application
    case captionStyles

    func open() async throws {
        switch self {
        case .application:
            guard let url = URL(string: UIApplication.openSettingsURLString), await UIApplication.shared.open(url) else {
                throw ErrorMessage(L10n.unableToOpenSettings)
            }

        case .captionStyles:
            guard #available(iOS 26.4, tvOS 26.4, *), AccessibilitySettings.canOpenSettings(for: .captionStyles) else {
                throw ErrorMessage(L10n.unableToOpenSettings)
            }

            try await AccessibilitySettings.openSettings(for: .captionStyles)
        }
    }
}
