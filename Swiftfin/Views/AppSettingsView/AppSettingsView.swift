//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI

struct AppSettingsView: View {

    @Default(.accentColor)
    private var accentColor
    @Default(.appearance)
    private var appearance
    @Default(.signOutOnClose)
    private var signOutOnClose

    @EnvironmentObject
    private var router: BasicAppSettingsCoordinator.Router

    @StateObject
    private var viewModel = SettingsViewModel()

    var body: some View {
        Form {

            ChevronButton(title: L10n.about)
                .onSelect {
                    router.route(to: \.about, viewModel)
                }

            Section(L10n.accessibility) {

                ChevronButton(title: L10n.appIcon)
                    .onSelect {
                        router.route(to: \.appIconSelector, viewModel)
                    }

                CaseIterablePicker(
                    title: L10n.appearance,
                    selection: $appearance
                )
            }

            SignOutIntervalSection()

            ChevronButton(title: L10n.logs)
                .onSelect {
                    router.route(to: \.log)
                }
        }
        .navigationTitle(L10n.advanced)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
    }
}
