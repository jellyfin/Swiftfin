//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension AppSettingsView {

    struct SignOutIntervalSection: View {

        @EnvironmentObject
        private var router: AppSettingsCoordinator.Router

        @Default(.backgroundSignOutInterval)
        private var backgroundSignOutInterval
        @Default(.signOutOnBackground)
        private var signOutOnBackground
        @Default(.signOutOnClose)
        private var signOutOnClose

        @State
        private var isEditingBackgroundSignOutInterval: Bool = false

        var body: some View {
            Section {
                Toggle(L10n.signoutClose, isOn: $signOutOnClose)
            } footer: {
                Text(L10n.signoutCloseFooter)
            }

            Section {
                Toggle(L10n.signoutBackground, isOn: $signOutOnBackground)

                if signOutOnBackground {
                    ChevronButton(
                        L10n.duration,
                        subtitle: Text(backgroundSignOutInterval, format: .hourMinute)
                    )
                    .onSelect {
                        router.route(to: \.hourPicker)
                    }
                }
            } footer: {
                Text(
                    L10n.signoutBackgroundFooter
                )
            }
        }
    }
}
