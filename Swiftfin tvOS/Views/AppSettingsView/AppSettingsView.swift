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

struct AppSettingsView: View {

    @Default(.selectUserUseSplashscreen)
    private var selectUserUseSplashscreen
    @Default(.selectUserAllServersSplashscreen)
    private var selectUserAllServersSplashscreen

    @Default(.appAppearance)
    private var appearance

    @EnvironmentObject
    private var router: AppSettingsCoordinator.Router

    @StateObject
    private var viewModel = SettingsViewModel()

    @State
    private var resetUserSettingsSelected: Bool = false
    @State
    private var removeAllServersSelected: Bool = false

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(.jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

                TextPairView(
                    leading: L10n.version,
                    trailing: "\(UIApplication.appVersion ?? .emptyDash) (\(UIApplication.bundleVersion ?? .emptyDash))"
                )

                Section {

                    Toggle(L10n.useSplashscreen, isOn: $selectUserUseSplashscreen)

                    if selectUserUseSplashscreen {
                        Menu {
                            Picker(L10n.servers, selection: $selectUserAllServersSplashscreen) {

                                Label(L10n.random, systemImage: "dice.fill")
                                    .tag(SelectUserServerSelection.all)

                                ForEach(viewModel.servers) { server in
                                    Text(server.name)
                                        .tag(SelectUserServerSelection.server(id: server.id))
                                }
                            }
                        } label: {
                            HStack {
                                Text(L10n.servers)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if selectUserAllServersSplashscreen == .all {
                                    Label(L10n.random, systemImage: "dice.fill")
                                } else if let server = viewModel.servers.first(
                                    where: { server in
                                        selectUserAllServersSplashscreen == .server(id: server.id)
                                    }
                                ) {
                                    Text(server.name)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(.zero)
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
    }
}
