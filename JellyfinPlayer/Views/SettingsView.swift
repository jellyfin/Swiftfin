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
    @Default(.overlayType) var overlayType
    @Default(.videoPlayerJumpForward) var jumpForwardLength
    @Default(.videoPlayerJumpBackward) var jumpBackwardLength
    @Default(.jumpGesturesEnabled) var jumpGesturesEnabled

    var body: some View {
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
                            .foregroundColor(.white)
                        Spacer()
                        Text(viewModel.server.name)
                            .foregroundColor(.jellyfinPurple)

                        Image(systemName: "chevron.right")
                    }
                }

                Button {
                    settingsRouter.dismissCoordinator {
                        SessionManager.main.logout()
                    }
                } label: {
                    Text("Switch User")
                        .font(.callout)
                }
            }

            Section(header: Text("Networking")) {
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
                
                Toggle("Jump Gestures Enabled", isOn: $jumpGesturesEnabled)
                
                Button {
                    settingsRouter.route(to: \.overlaySettings)
                } label: {
                    HStack {
                        Text("Overlay")
                            .foregroundColor(.white)
                        Spacer()
                        Text(overlayType.label)
                        
                        Image(systemName: "chevron.right")
                    }
                }
            }

            Section(header: L10n.accessibility.text) {
//                Toggle("Automatically show subtitles", isOn: $isAutoSelectSubtitles)
//                SearchablePicker(label: "Preferred subtitle language",
//                                 options: viewModel.langs,
//                                 optionToString: { $0.name },
//                                 selected: Binding<TrackLanguage>(get: {
//                                                                      viewModel.langs
//                                                                          .first(where: { $0.isoCode == autoSelectSubtitlesLangcode
//                                                                          }) ??
//                                                                          .auto
//                                                                  },
//                                                                  set: { autoSelectSubtitlesLangcode = $0.isoCode }))
//                SearchablePicker(label: "Preferred audio language",
//                                 options: viewModel.langs,
//                                 optionToString: { $0.name },
//                                 selected: Binding<TrackLanguage>(get: {
//                                                                      viewModel.langs
//                                                                          .first(where: { $0.isoCode == autoSelectAudioLangcode }) ??
//                                                                          .auto
//                                                                  },
//                                                                  set: { autoSelectAudioLangcode = $0.isoCode }))
                Picker(L10n.appearance, selection: $appAppearance) {
                    ForEach(AppAppearance.allCases, id: \.self) { appearance in
                        Text(appearance.localizedName).tag(appearance.rawValue)
                    }
                }
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
