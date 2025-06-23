//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AdminDashboardView {

    struct DeviceSection: View {

        let client: String?
        let device: String?
        let version: String?

        var body: some View {
            Section(L10n.device) {
                LabeledContent(
                    L10n.device,
                    value: device ?? L10n.unknown
                )

                LabeledContent(
                    L10n.client,
                    value: client ?? L10n.unknown
                )

                LabeledContent(
                    L10n.version,
                    value: version ?? L10n.unknown
                )
            }
        }
    }
}
