//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreData
import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct SettingsView: View {
    
    @Injected(Container.userSession)
    private var userSession

    @EnvironmentObject
    private var router: SettingsCoordinator.Router
    
    @ObservedObject
    var viewModel: SettingsViewModel

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(uiImage: UIImage(named: "App Icon")!)
                    .resizable()
                    .aspectRatio(1.667, contentMode: .fit)
                    .cornerRadius(30)
                    .shadow(radius: 10, x: 0, y: 10)
                    .padding()
            }
            .contentView {
                Section {
                    
                    Button {} label: {
                        TextPairView(
                            leading: L10n.user,
                            trailing: userSession.user.username
                        )
                    }
                    
                    ChevronButton(
                        title: L10n.server,
                        subtitle: userSession.server.name
                    )
//                    .onSelect {
//                        router.route(to: \.serverDetail)
//                    }
                    
                    Button {
                        
                    } label: {
                        L10n.switchUser.text
                            .foregroundColor(.jellyfinPurple)
                    }
                }
                
                Section {
                    ChevronButton(title: L10n.appearance)
                        .onSelect {
                            router.route(to: \.appearanceSelector)
                        }
                } header: {
                    L10n.appearance.text
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: .init())
            .preferredColorScheme(.light)
    }
}
