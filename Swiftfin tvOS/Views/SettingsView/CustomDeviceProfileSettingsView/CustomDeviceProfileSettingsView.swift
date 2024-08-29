//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

struct CustomDeviceProfileSettingsView: View {
    @Default(.VideoPlayer.Playback.compatibilityMode)
    private var compatibilityMode
    @Default(.VideoPlayer.Playback.customDeviceProfileAction)
    private var customDeviceProfileAction

    @EnvironmentObject
    private var router: CustomDeviceProfileSettingsCoordinator.Router

    @State
    private var isEditing = false
    @State
    private var customDeviceProfiles: [PlaybackDeviceProfile] = []

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "doc.badge.gearshape")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                Section {
                    InlineEnumToggle(
                        title: L10n.behavior,
                        selection: $customDeviceProfileAction
                    )
                } header: {
                    L10n.behavior.text
                } footer: {
                    customDeviceProfileAction == .add
                        ? L10n.customDeviceProfileAdd.text
                        : L10n.customDeviceProfileReplace.text
                }
                Section {
                    ForEach($customDeviceProfiles, id: \.id) { $profile in
                        CustomProfileButton(
                            profile: profile,
                            isEditing: isEditing,
                            onSelect: { router.route(to: \.customDeviceProfileEditor, $profile) },
                            onDelete: { removeProfile(profile) }
                        )
                    }
                } header: {
                    HStack {
                        Text(L10n.customProfile)
                        Spacer()
                        HStack(spacing: 4) {
                            if !isEditing {
                                Button("Add") {
                                    addProfile()
                                }
                            }
                            Button(isEditing ? "Done" : "Edit") {
                                isEditing.toggle()
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.profiles)
            .onAppear(perform: loadProfiles)
            .onChange(of: customDeviceProfiles) {
                updateProfiles()
            }
    }

    private func loadProfiles() {
        if let userID = Container.shared.currentUserSession()?.user.id {
            customDeviceProfiles = StoredValues[.User.customDeviceProfiles(id: userID)]
        }
    }

    private func updateProfiles() {
        if let userID = Container.shared.currentUserSession()?.user.id {
            StoredValues[.User.customDeviceProfiles(id: userID)] = customDeviceProfiles
        }
    }

    private func removeProfile(_ profile: PlaybackDeviceProfile) {
        customDeviceProfiles.removeAll { $0.id == profile.id }
        updateProfiles()
    }

    private func addProfile() {
        let newProfile = PlaybackDeviceProfile(type: .video)
        customDeviceProfiles.append(newProfile)
        updateProfiles()

        if let index = customDeviceProfiles.firstIndex(where: { $0.id == newProfile.id }) {
            router.route(to: \.customDeviceProfileEditor, $customDeviceProfiles[index])
        }
    }
}
