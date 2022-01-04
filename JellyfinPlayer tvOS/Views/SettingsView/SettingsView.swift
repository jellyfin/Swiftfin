/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import CoreData
import SwiftUI
import Defaults
import JellyfinAPI

struct SettingsView: View {

    @EnvironmentObject var settingsRouter: SettingsCoordinator.Router
    @ObservedObject var viewModel: SettingsViewModel

    @Default(.autoSelectAudioLangCode) var autoSelectAudioLangcode
    @Default(.videoPlayerJumpForward) var jumpForwardLength
    @Default(.videoPlayerJumpBackward) var jumpBackwardLength
    @Default(.downActionShowsMenu) var downActionShowsMenu

    var body: some View {
        GeometryReader { reader in
            HStack {
                
                Image(uiImage: UIImage(named: "App Icon")!)
                    .scaleEffect(2)
                    .frame(width: reader.size.width / 2)
                
                Form {
                    Section(header: EmptyView()) {
                        HStack {
                            Text("User")
                            Spacer()
                            Text(viewModel.user.username)
                                .foregroundColor(.jellyfinPurple)
                        }

                        Button {
                            settingsRouter.route(to: \.serverDetail)
                        } label: {
                            HStack {
                                Text("Server")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(viewModel.server.name)
                                    .foregroundColor(.jellyfinPurple)

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.jellyfinPurple)
                            }
                        }

                        Button {
                            SessionManager.main.logout()
                        } label: {
                            Text("Switch User")
                                .foregroundColor(Color.jellyfinPurple)
                                .font(.callout)
                        }
                    }
                    
                    Section(header: Text("Video Player")) {
                        Picker("Jump Forward Length", selection: $jumpForwardLength) {
                            ForEach(VideoPlayerJumpLength.allCases, id: \.self) { length in
                                Text(length.label).tag(length.rawValue)
                            }
                        }

                        Picker("Jump Backward Length", selection: $jumpBackwardLength) {
                            ForEach(VideoPlayerJumpLength.allCases, id: \.self) { length in
                                Text(length.label).tag(length.rawValue)
                            }
                        }
                        
                        Toggle("Press Down for Menu", isOn: $downActionShowsMenu)
                        
                        Button {
                            settingsRouter.route(to: \.overlaySettings)
                        } label: {
                            HStack {
                                Text("Overlay")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                        
                        Button {
                            settingsRouter.route(to: \.experimentalSettings)
                        } label: {
                            HStack {
                                Text("Experimental")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel(server: .sample, user: .sample))
    }
}
