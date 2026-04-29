//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayerSettingsView {

    struct SupplementSection: View {

        @Default(.VideoPlayer.supplements)
        private var supplements

        @Router
        private var router

        var body: some View {
            Section(L10n.supplements) {
                ChevronButton(L10n.supplements) {
                    router.route(to: .supplementSelector(
                        selectedSupplementsBinding: $supplements
                    ))
                }
            }
        }
    }
}
