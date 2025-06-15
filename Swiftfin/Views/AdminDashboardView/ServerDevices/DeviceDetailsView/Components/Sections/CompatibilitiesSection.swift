//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension DeviceDetailsView {
    struct CapabilitiesSection: View {
        var device: DeviceInfoDto

        var body: some View {
            Section(L10n.capabilities) {
                if let supportsMediaControl = device.capabilities?.isSupportsMediaControl {
                    LabeledContent(L10n.supportsMediaControl, value: supportsMediaControl ? L10n.yes : L10n.no)
                }

                if let supportsPersistentIdentifier = device.capabilities?.isSupportsPersistentIdentifier {
                    LabeledContent(L10n.supportsPersistentIdentifier, value: supportsPersistentIdentifier ? L10n.yes : L10n.no)
                }
            }
        }
    }
}
