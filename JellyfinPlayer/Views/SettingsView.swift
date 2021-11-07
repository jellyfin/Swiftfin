/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import CoreData
import Defaults
import Stinsen
import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var settingsRouter: SettingsCoordinator.Router
    @ObservedObject var viewModel: SettingsViewModel

    @Default(.inNetworkBandwidth) var inNetworkStreamBitrate
    @Default(.outOfNetworkBandwidth) var outOfNetworkStreamBitrate
    @Default(.isAutoSelectSubtitles) var isAutoSelectSubtitles
    @Default(.autoSelectSubtitlesLangCode) var autoSelectSubtitlesLangcode
    @Default(.autoSelectAudioLangCode) var autoSelectAudioLangcode
    @Default(.appAppearance) var appAppearance
    @Default(.videoPlayerJumpForward) var jumpForwardLength
    @Default(.videoPlayerJumpBackward) var jumpBackwardLength

    var body: some View {
        Form {
            Section(header: EmptyView()) {
                
                // There is a bug where the SettingsView attmempts to remake itself upon signing out
                //     so this check is made
                if SessionManager.main.currentLogin == nil {
                    HStack {
                        Text("User")
                        Spacer()
                        Text("")
                            .foregroundColor(.jellyfinPurple)
                    }

                    Button {
                        settingsRouter.route(to: \.serverDetail)
                    } label: {
                        HStack {
                            Text("Server")
                            Spacer()
                            Text("")
                                .foregroundColor(.jellyfinPurple)

                            Image(systemName: "chevron.right")
                        }
                    }
                } else {
                    HStack {
                        Text("User")
                        Spacer()
                        Text(SessionManager.main.currentLogin.user.username)
                            .foregroundColor(.jellyfinPurple)
                    }

                    Button {
                        settingsRouter.route(to: \.serverDetail)
                    } label: {
                        HStack {
                            Text("Server")
                            Spacer()
                            Text(SessionManager.main.currentLogin.server.name)
                                .foregroundColor(.jellyfinPurple)

                            Image(systemName: "chevron.right")
                        }
                    }
                }

                Button {
                    settingsRouter.dismissCoordinator {
                        SessionManager.main.logout()
                    }
                } label: {
                    Text("Sign out")
                        .font(.callout)
                }
            }
            
            Section(header: Text("Playback")) {
                Picker("Default local quality", selection: $inNetworkStreamBitrate) {
                    ForEach(self.viewModel.bitrates, id: \.self) { bitrate in
                        Text(bitrate.name).tag(bitrate.value)
                    }
                }

                Picker("Default remote quality", selection: $outOfNetworkStreamBitrate) {
                    ForEach(self.viewModel.bitrates, id: \.self) { bitrate in
                        Text(bitrate.name).tag(bitrate.value)
                    }
                }

                Picker("Jump Forward Length", selection: $jumpForwardLength) {
                    ForEach(self.viewModel.videoPlayerJumpLengths, id: \.self) { length in
                        Text(length.label).tag(length.rawValue)
                    }
                }

                Picker("Jump Backward Length", selection: $jumpBackwardLength) {
                    ForEach(self.viewModel.videoPlayerJumpLengths, id: \.self) { length in
                        Text(length.label).tag(length.rawValue)
                    }
                }
            }

            Section(header: R.string.localizable.accessibility.text) {
                Toggle("Automatically show subtitles", isOn: $isAutoSelectSubtitles)
                SearchablePicker(label: "Preferred subtitle language",
                                 options: viewModel.langs,
                                 optionToString: { $0.name },
                                 selected: Binding<TrackLanguage>(get: {
                                                                      viewModel.langs
                                                                          .first(where: { $0.isoCode == autoSelectSubtitlesLangcode
                                                                          }) ??
                                                                          .auto
                                                                  },
                                                                  set: { autoSelectSubtitlesLangcode = $0.isoCode }))
                SearchablePicker(label: "Preferred audio language",
                                 options: viewModel.langs,
                                 optionToString: { $0.name },
                                 selected: Binding<TrackLanguage>(get: {
                                                                      viewModel.langs
                                                                          .first(where: { $0.isoCode == autoSelectAudioLangcode }) ??
                                                                          .auto
                                                                  },
                                                                  set: { autoSelectAudioLangcode = $0.isoCode }))
                Picker(R.string.localizable.appearance(), selection: $appAppearance) {
                    ForEach(self.viewModel.appearances, id: \.self) { appearance in
                        Text(appearance.localizedName).tag(appearance.rawValue)
                    }
                }.onChange(of: appAppearance, perform: { _ in
                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = appAppearance.style
                })
            }
        }
        .navigationBarTitle("Settings", displayMode: .inline)
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
