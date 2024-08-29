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
    private var router: SettingsCoordinator.Router

    @State
    private var isEditing = false
    @State
    private var customDeviceProfiles: [PlaybackDeviceProfile] = []

    var body: some View {
        List {
            Section {
                CaseIterablePicker(
                    L10n.behavior,
                    selection: $customDeviceProfileAction
                )
            } header: {
                L10n.behavior.text
            } footer: {
                customDeviceProfileAction == .add
                    ? L10n.customDeviceProfileAdd.text
                    : L10n.customDeviceProfileReplace.text
            }

            Section(header: headerView) {
                ForEach($customDeviceProfiles, id: \.id) { $profile in
                    CustomProfileButton(
                        profile: profile,
                        onSelect: { router.route(to: \.customDeviceProfileEditor, $profile) }
                    )
                }
                .onDelete(perform: removeProfile)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(L10n.profiles)
        .onAppear(perform: loadProfiles)
        .onChange(of: customDeviceProfiles) { _ in
            updateProfiles()
        }
    }

    private var headerView: some View {
        HStack {
            Text(L10n.customProfile)
            Spacer()
            Button("Add") {
                addProfile()
            }
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

    private func removeProfile(at offsets: IndexSet) {
        customDeviceProfiles.remove(atOffsets: offsets)
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
