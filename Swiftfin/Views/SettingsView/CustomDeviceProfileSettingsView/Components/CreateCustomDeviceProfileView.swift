//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension CustomDeviceProfileSettingsView {

    struct CreateCustomDeviceProfileView: View {

        @StoredValue(.User.customDeviceProfiles)
        private var customDeviceProfiles

        @EnvironmentObject
        private var router: SettingsCoordinator.Router

        @State
        private var customProfile: CustomDeviceProfile = .init(
            type: .video,
            useAsTranscodingProfile: false,
            audio: [],
            video: [],
            container: []
        )
        @State
        private var isPresentingNotSaved = false

        private var isValid: Bool {
            customProfile.audio.isNotEmpty &&
                customProfile.video.isNotEmpty &&
                customProfile.container.isNotEmpty
        }

        var body: some View {
            EditCustomDeviceProfileView(profile: $customProfile)
                .interactiveDismissDisabled(true)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .navigationBarCloseButton {
                    isPresentingNotSaved = true
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add") {
                            customDeviceProfiles.append(customProfile)
                            router.popLast()
                        }
                        .disabled(!isValid)
                    }
                }
                .alert("Profile not saved", isPresented: $isPresentingNotSaved) {
                    Button("Close", role: .destructive) {
                        router.popLast()
                    }
                }
        }
    }
}
