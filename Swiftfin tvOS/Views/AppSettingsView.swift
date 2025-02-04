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

    @ObservedObject
    var viewModel = SettingsViewModel()

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

                Section(L10n.accessibility) {

                    // TODO: supposedly supported but not working
//                    ChevronButton(L10n.appIcon)
//                        .onSelect {
//                                router.route(to: \.appIconSelector, viewModel)
//                        }

//                    if !selectUserUseSplashscreen {
//                        CaseIterablePicker(
//                            L10n.appearance,
//                            selection: $appearance
//                        )
//                    }
                }

                Section {

                    Toggle("Use splashscreen", isOn: $selectUserUseSplashscreen)

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
                    Text("Splashscreen")
                } footer: {
                    if selectUserUseSplashscreen {
                        Text("When All Servers is selected, use the splashscreen from a single server or a random server")
                    }
                }

//                    SignOutIntervalSection()

                ChevronButton(L10n.logs)
                    .onSelect {
                        router.route(to: \.log)
                    }
            }
    }
}
