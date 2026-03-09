//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: move sign out-stuff into super user when implemented

struct AppSettingsView: View {

    #if os(tvOS)
    typealias PlatformPicker = ListRowMenu
    #else
    typealias PlatformPicker = Picker
    #endif

    @Default(.selectUserUseSplashscreen)
    private var selectUserUseSplashscreen
    @Default(.selectUserAllServersSplashscreen)
    private var selectUserAllServersSplashscreen

    @Default(.backgroundSignOutInterval)
    private var backgroundSignOutInterval
    @Default(.signOutOnBackground)
    private var signOutOnBackground
    @Default(.signOutOnClose)
    private var signOutOnClose

    #if os(iOS)
    @Default(.appAppearance)
    private var appearance
    #endif

    @Router
    private var router

    @StateObject
    private var viewModel = SettingsViewModel()

    var body: some View {
        Form(image: .jellyfinBlobBlue) {

            Section("Swiftfin") {
                ChevronButton(L10n.about) {
                    router.route(to: .aboutApp)
                }
            }

            #if os(iOS)
            Section(L10n.customize) {

                ChevronButton(L10n.appIcon) {
                    // TODO: Create NavigationRoute.appIconSelector
                    router.route(to: .appIconSelector(viewModel: viewModel))
                }

                if !selectUserUseSplashscreen {
                    Picker(
                        L10n.appearance,
                        selection: $appearance
                    )
                }
            }
            #endif

            Section {
                Toggle(L10n.useSplashscreen, isOn: $selectUserUseSplashscreen)

                if selectUserUseSplashscreen {
                    PlatformPicker(L10n.servers, selection: $selectUserAllServersSplashscreen) {
                        Label(L10n.random, systemImage: "dice.fill")
                            .tag(SelectUserServerSelection.all)

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

            Section {
                Toggle(L10n.signoutClose, isOn: $signOutOnClose)
            } footer: {
                Text(L10n.signoutCloseFooter)
            }

            Section {
                Toggle(L10n.signoutBackground, isOn: $signOutOnBackground)

                if signOutOnBackground {
                    HourMinutePicker(L10n.duration, interval: $backgroundSignOutInterval)
                }
            } footer: {
                Text(L10n.signoutBackgroundFooter)
            }

            ChevronButton(L10n.logs) {
                router.route(to: .log)
            }
        }
        .animation(.linear, value: selectUserUseSplashscreen)
        .navigationTitle(L10n.advanced)
        .navigationBarCloseButton {
            router.dismiss()
        }
    }
}
