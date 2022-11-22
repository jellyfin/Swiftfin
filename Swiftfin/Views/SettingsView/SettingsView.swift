//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreData
import Defaults
import Stinsen
import SwiftUI

struct SettingsView: View {

    @EnvironmentObject
    private var settingsRouter: SettingsCoordinator.Router
    @ObservedObject
    var viewModel: SettingsViewModel

    @Default(.appAppearance)
    var appAppearance

    var body: some View {
        Form {
            Section(header: EmptyView()) {
                HStack {
                    L10n.user.text
                    Spacer()
                    Text(viewModel.user.username)
                        .foregroundColor(.jellyfinPurple)
                }
                
                ChevronButton(title: L10n.server, subtitle: viewModel.server.name)
                    .onSelect {
                        settingsRouter.route(to: \.serverDetail)
                    }
                
                ChevronButton(title: L10n.quickConnect)
                    .onSelect {
                        settingsRouter.route(to: \.quickConnect)
                    }

                Button {
                    settingsRouter.dismissCoordinator {
                        SessionManager.main.logout()
                    }
                } label: {
                    L10n.switchUser.text
                        .font(.callout)
                }
            }

            Section(header: L10n.videoPlayer.text) {
                
                ChevronButton(title: L10n.videoPlayer)
                    .onSelect {
                        settingsRouter.route(to: \.videoPlayerSettings)
                    }
            }

            Section(header: L10n.accessibility.text) {
                
                EnumPicker(title: L10n.appearance, selection: $appAppearance)
                
                ChevronButton(title: L10n.customize)
                    .onSelect {
                        settingsRouter.route(to: \.customizeViewsSettings)
                    }
                
                ChevronButton(title: L10n.experimental)
                    .onSelect {
                        settingsRouter.route(to: \.experimentalSettings)
                    }
            }
            
            ChevronButton(title: L10n.about)
                .onSelect {
                    settingsRouter.route(to: \.about)
                }
        }
        .navigationBarTitle(L10n.settings, displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    settingsRouter.dismissCoordinator()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
    }
}
