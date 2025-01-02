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
    private var router: SettingsCoordinator.Router

    private var isValid: Bool {
        customDeviceProfileAction == .add ||
            customProfiles.isNotEmpty
    }

    private func removeProfile(at offsets: IndexSet) {
        customProfiles.remove(atOffsets: offsets)
    }

    var body: some View {
        List {
            Section {
                CaseIterablePicker(
                    L10n.behavior,
                    selection: $customDeviceProfileAction
                )
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
                            .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                    }
                }
            }

            Section(L10n.profiles) {

                if customProfiles.isEmpty {
                    Button("Add profile") {
                        router.route(to: \.createCustomDeviceProfile)
                    }
                }

                ForEach($customProfiles, id: \.self) { $profile in
                    CustomProfileButton(profile: profile) {
                        router.route(to: \.editCustomDeviceProfile, $profile)
                    }
                }
                .onDelete(perform: removeProfile)
            }
        }
        .navigationTitle(L10n.profiles)
        .topBarTrailing {
            if customProfiles.isNotEmpty {
                Button(L10n.add) {
                    UIDevice.impact(.light)
                    router.route(to: \.createCustomDeviceProfile)
                }
                .buttonStyle(.toolbarPill)
            }
        }
    }
}
