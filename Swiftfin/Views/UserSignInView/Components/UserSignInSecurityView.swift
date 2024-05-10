//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// Note: this could be renamed from Security, but that's all it's used for atow

extension UserSignInView {

    struct SecurityView: View {

        @EnvironmentObject
        private var router: UserSignInCoordinator.Router

        @Binding
        private var signInPolicy: UserSignInPolicy

        @State
        private var updateSignInPolicy: UserSignInPolicy

        init(signInPolicy: Binding<UserSignInPolicy>) {
            self._signInPolicy = signInPolicy
            self._updateSignInPolicy = State(initialValue: signInPolicy.wrappedValue)
        }

        var body: some View {
            List {

                Section {
                    CaseIterablePicker(title: "Access", selection: $updateSignInPolicy)
                } footer: {
                    // TODO: descriptions of each section

                    VStack(alignment: .leading, spacing: 10) {
                        Text(
                            "Additional security options for users signed in to this device. This does not change any Jellyfin server user settings."
                        )

                        BulletedList {

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Device Authentication")
                                    .fontWeight(.semibold)

                                Text("Require local device authentication when signing in to the user.")
                            }
                            .padding(.bottom, 15)

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Pin")
                                    .fontWeight(.semibold)

                                Text("Require a local pin when signing in to the user.")
                            }
                            .padding(.bottom, 15)

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Save")
                                    .fontWeight(.semibold)

                                Text("Save the user to this device without any local authentication.")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.popLast()
            }
            .onChange(of: updateSignInPolicy) { _ in
                signInPolicy = updateSignInPolicy
            }
        }
    }
}
