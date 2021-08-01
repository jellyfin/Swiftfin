/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import CoreData
import SwiftUI
import Defaults

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var viewModel: SettingsViewModel

    @Binding var close: Bool
    @Default(.inNetworkBandwidth) var inNetworkStreamBitrate
    @Default(.outOfNetworkBandwidth) var outOfNetworkStreamBitrate
    @Default(.isAutoSelectSubtitles) var isAutoSelectSubtitles
    @Default(.autoSelectSubtitlesLangCode) var autoSelectSubtitlesLangcode
    @Default(.autoSelectAudioLangCode) var autoSelectAudioLangcode
    @Default(.appAppearance) var appAppearance
    @State private var username: String = ""

    func onAppear() {
        username = SessionManager.current.user?.username ?? ""
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Playback settings")) {
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

                Section(header: Text("Accessibility")) {
                    Toggle("Automatically show subtitles", isOn: $isAutoSelectSubtitles)
                    SearchablePicker(label: "Preferred subtitle language",
                                     options: viewModel.langs,
                                     optionToString: { $0.name },
                                     selected: Binding<TrackLanguage>(
                                        get: { viewModel.langs.first(where: { $0.isoCode == autoSelectSubtitlesLangcode }) ?? .auto },
                                        set: {autoSelectSubtitlesLangcode = $0.isoCode}
                                     )
                    )
                    SearchablePicker(label: "Preferred audio language",
                                     options: viewModel.langs,
                                     optionToString: { $0.name },
                                     selected: Binding<TrackLanguage>(
                                        get: { viewModel.langs.first(where: { $0.isoCode == autoSelectAudioLangcode }) ?? .auto },
                                        set: { autoSelectAudioLangcode = $0.isoCode}
                                     )
                    )
                    Picker(NSLocalizedString("Appearance", comment: ""), selection: $appAppearance) {
                        ForEach(self.viewModel.appearances, id: \.self) { appearance in
                            Text(appearance.localizedName).tag(appearance.rawValue)
                        }
                    }.onChange(of: appAppearance, perform: { value in
                        guard let appearance = AppAppearance(rawValue: value) else { return }
                        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = appearance.style
                    })
                }

                Section(header: Text(ServerEnvironment.current.server.name ?? "")) {
                    HStack {
                        Text("Signed in as \(username)").foregroundColor(.primary)
                        Spacer()
                        Button {
                            print("logging out")
                            close = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                let nc = NotificationCenter.default
                                nc.post(name: Notification.Name("didSignOut"), object: nil)
                            }
                        } label: {
                            Text("Switch user").font(.callout)
                        }
                    }
                    Button {
                        close = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            SessionManager.current.logout()
                            let nc = NotificationCenter.default
                            nc.post(name: Notification.Name("didSignOut"), object: nil)
                        }
                    } label: {
                        Text("Sign out").font(.callout)
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        close = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }.onAppear(perform: onAppear)
    }
}
