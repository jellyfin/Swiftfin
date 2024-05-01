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
    @Default(.appAppearance)
    private var appAppearance

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

            Section {
                CaseIterablePicker(title: L10n.appearance, selection: $appAppearance)

                ChevronButton(title: L10n.appIcon)
                    .onSelect {
                        router.route(to: \.appIconSelector, viewModel)
                    }
            } header: {
                L10n.accessibility.text
            }

            Section {
                ColorPicker(L10n.accentColor, selection: $accentColor, supportsOpacity: false)
            } footer: {
                L10n.accentColorDescription.text
            }

            ChevronButton(title: L10n.logs)
                .onSelect {
                    router.route(to: \.log)
                }

            // TODO: come up with exact rules and implement
//            ChevronButton(title: "Super User")
        }
        .navigationTitle(L10n.advanced)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
    }
}
