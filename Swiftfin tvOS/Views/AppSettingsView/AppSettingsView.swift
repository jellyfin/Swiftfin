//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults

import SwiftUI

struct AppSettingsView: View {

    @Default(.selectUserUseSplashscreen)
    private var selectUserUseSplashscreen
    @Default(.selectUserAllServersSplashscreen)
    private var selectUserAllServersSplashscreen

    @Default(.appAppearance)
    private var appearance

    @Router
    private var router

    @StateObject
    private var viewModel = SettingsViewModel()

    @State
    private var resetUserSettingsSelected: Bool = false
    @State
    private var removeAllServersSelected: Bool = false

    private var selectedServer: ServerState? {
        viewModel.servers.first { server in
            selectUserAllServersSplashscreen == .server(id: server.id)
        }
    }

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(.jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

                LabeledContent(
                    L10n.version,
                    value: "\(UIApplication.appVersion ?? .emptyDash) (\(UIApplication.bundleVersion ?? .emptyDash))"
                )

                Section {

                    Toggle(L10n.useSplashscreen, isOn: $selectUserUseSplashscreen)

                    if selectUserUseSplashscreen {
                        ListRowMenu(L10n.servers) {
                            if selectUserAllServersSplashscreen == .all {
                                Label(L10n.random, systemImage: "dice.fill")
                            } else if let selectedServer {
                                Text(selectedServer.name)
                            } else {
                                Text(L10n.none)
                            }
                        } content: {
                            Picker(L10n.servers, selection: $selectUserAllServersSplashscreen) {
                                Label(L10n.random, systemImage: "dice.fill")
                                    .tag(SelectUserServerSelection.all)

                                ForEach(viewModel.servers) { server in
                                    Text(server.name)
                                        .tag(SelectUserServerSelection.server(id: server.id))
                                }
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

                ChevronButton(L10n.logs) {
                    router.route(to: .log)
                }
            }
            .navigationTitle(L10n.advanced)
    }
}
