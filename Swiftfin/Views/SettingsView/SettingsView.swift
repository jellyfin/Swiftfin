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

    @Default(.appAppearance)
    private var appAppearance
    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType
    
    @EnvironmentObject
    private var router: SettingsCoordinator.Router
    
    @ObservedObject
    var viewModel: SettingsViewModel

    var body: some View {
        Form {
            
            Section {
                HStack {
                    L10n.user.text
                    Spacer()
                    Text(viewModel.user.username)
                        .foregroundColor(.jellyfinPurple)
                }
                
                ChevronButton(title: L10n.server, subtitle: viewModel.server.name)
                    .onSelect {
                        router.route(to: \.serverDetail)
                    }
                
                ChevronButton(title: L10n.quickConnect)
                    .onSelect {
                        router.route(to: \.quickConnect)
                    }

                Button {
                    router.dismissCoordinator {
                        SessionManager.main.logout()
                    }
                } label: {
                    L10n.switchUser.text
                        .font(.callout)
                }
            }
            
            Section {
                EnumPicker(
                    title: "Video Player Type",
                    selection: $videoPlayerType
                )
                
                ChevronButton(title: "Native Player")
                    .onSelect {
                        router.route(to: \.nativePlayerSettings)
                    }
                
                ChevronButton(title: L10n.videoPlayer)
                    .onSelect {
                        router.route(to: \.videoPlayerSettings)
                    }
            } header: {
                L10n.videoPlayer.text
            }
            
            Section {
                EnumPicker(title: L10n.appearance, selection: $appAppearance)
                
                ChevronButton(title: L10n.customize)
                    .onSelect {
                        router.route(to: \.customizeViewsSettings)
                    }
                
                ChevronButton(title: L10n.experimental)
                    .onSelect {
                        router.route(to: \.experimentalSettings)
                    }
            } header: {
                L10n.accessibility.text
            }
            
            ChevronButton(title: L10n.about)
                .onSelect {
                    router.route(to: \.about)
                }
        }
        .navigationBarTitle(L10n.settings, displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    router.dismissCoordinator()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
    }
}
