//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

struct CustomDeviceProfileSettingsView: View {

    @Default(.VideoPlayer.Playback.customDeviceProfileAction)
    private var customDeviceProfileAction

    @StoredValue(.User.customDeviceProfiles)
    private var customProfiles: [CustomDeviceProfile]

    @EnvironmentObject
    private var router: CustomDeviceProfileCoordinator.Router

    private var isValid: Bool {
        customDeviceProfileAction == .add || customProfiles.isNotEmpty
    }

    private func removeProfile(at offsets: IndexSet) {
        customProfiles.remove(atOffsets: offsets)
    }

    private func deleteProfile(_ profile: CustomDeviceProfile) {
        if let index = customProfiles.firstIndex(of: profile) {
            customProfiles.remove(at: index)
        }
    }

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "doc.on.doc")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                Section {
                    ListRowMenu(L10n.behavior, selection: $customDeviceProfileAction)
                } header: {
                    L10n.behavior.text
                } footer: {
                    VStack(spacing: 8) {
                        switch customDeviceProfileAction {
                        case .add:
                            L10n.customDeviceProfileAdd.text
                        case .replace:
                            L10n.customDeviceProfileReplace.text
                        }

                        if !isValid {
                            Label("No profiles defined. Playback issues may occur.", systemImage: "exclamationmark.circle.fill")
                        }
                    }
                }

                Section {
                    if customProfiles.isEmpty {
                        Button("Add profile") {
                            router.route(to: \.createCustomDeviceProfile)
                        }
                    }

                    List {
                        ForEach($customProfiles, id: \.self) { $profile in
                            CustomProfileButton(profile: profile) {
                                router.route(to: \.editCustomDeviceProfile, $profile)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteProfile(profile)
                                } label: {
                                    Label(L10n.delete, systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: removeProfile)
                    }
                } header: {
                    HStack {
                        Text(L10n.profiles)
                        Spacer()
                        if customProfiles.isNotEmpty {
                            Button(L10n.add) {
                                router.route(to: \.createCustomDeviceProfile)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.profiles)
    }
}
