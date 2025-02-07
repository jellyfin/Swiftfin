//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI

// TODO: move sign out-stuff into super user when implemented

struct AppSettingsView: View {

    @Default(.accentColor)
    private var accentColor

    @Default(.appAppearance)
    private var appearance

    @Default(.selectUserUseSplashscreen)
    private var selectUserUseSplashscreen
    @Default(.selectUserAllServersSplashscreen)
    private var selectUserAllServersSplashscreen

    @Default(.signOutOnClose)
    private var signOutOnClose

    @EnvironmentObject
    private var router: AppSettingsCoordinator.Router

    @StateObject
    private var viewModel = SettingsViewModel()

    var body: some View {
        Form {

            ChevronButton(L10n.about)
                .onSelect {
                    router.route(to: \.about, viewModel)
                }

            Section(L10n.accessibility) {

                ChevronButton(L10n.appIcon)
                    .onSelect {
                        router.route(to: \.appIconSelector, viewModel)
                    }

                if !selectUserUseSplashscreen {
                    CaseIterablePicker(
                        L10n.appearance,
                        selection: $appearance
                    )
                }
            }

            Section {

                Toggle(L10n.useSplashscreen, isOn: $selectUserUseSplashscreen)

                if selectUserUseSplashscreen {
                    Picker(L10n.servers, selection: $selectUserAllServersSplashscreen) {

                        Section {
                            Label(L10n.random, systemImage: "dice.fill")
                                .tag(SelectUserServerSelection.all)
                        }

                        ForEach(viewModel.servers) { server in
                            Text(server.name)
                                .tag(SelectUserServerSelection.server(id: server.id))
                        }
                    }
                }
            } header: {
                Text(L10n.splashscreen)
            } footer: {
                if selectUserUseSplashscreen {
                    Text(L10n.splashscreenFooter)
                }
            }

            SignOutIntervalSection()

            ChevronButton(L10n.logs)
                .onSelect {
                    router.route(to: \.log)
                }
        }
        .animation(.linear, value: selectUserUseSplashscreen)
        .navigationTitle(L10n.advanced)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
    }
}
