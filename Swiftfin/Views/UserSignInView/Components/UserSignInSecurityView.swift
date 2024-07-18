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
        private var pinHint: String
        @Binding
        private var accessPolicy: UserAccessPolicy

        @State
        private var listSize: CGSize = .zero
        @State
        private var updatePinHint: String
        @State
        private var updateSignInPolicy: UserAccessPolicy

        init(
            pinHint: Binding<String>,
            accessPolicy: Binding<UserAccessPolicy>
        ) {
            self._pinHint = pinHint
            self._accessPolicy = accessPolicy
            self._updatePinHint = State(initialValue: pinHint.wrappedValue)
            self._updateSignInPolicy = State(initialValue: accessPolicy.wrappedValue)
        }

        var body: some View {
            List {

                Section {
                    CaseIterablePicker("Security", selection: $updateSignInPolicy)
                } footer: {
                    // TODO: descriptions of each section

                    VStack(alignment: .leading, spacing: 10) {
                        Text(
                            "Additional security for users signed in to this device. This does not change any Jellyfin server user settings."
                        )

                        // frame necessary with bug within BulletedList
                        BulletedList {

                            VStack(alignment: .leading, spacing: 5) {
                                Text(UserAccessPolicy.requireDeviceAuthentication.displayTitle)
                                    .fontWeight(.semibold)

                                Text("Require device authentication when signing in to the user.")
                            }
                            .padding(.bottom, 15)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(UserAccessPolicy.requirePin.displayTitle)
                                    .fontWeight(.semibold)

                                Text("Require a local pin when signing in to the user. This pin is unrecoverable.")
                            }
                            .padding(.bottom, 15)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(UserAccessPolicy.none.displayTitle)
                                    .fontWeight(.semibold)

                                Text("Save the user to this device without any local authentication.")
                            }
                        }
                        .frame(width: max(10, listSize.width - 50))
                    }
                }

                if accessPolicy == .requirePin {
                    Section {
                        TextField("Hint", text: $updatePinHint)
                    } header: {
                        Text("Hint")
                    } footer: {
                        Text("Set a hint when prompting for the pin.")
                    }
                }
            }
            .animation(.linear, value: accessPolicy)
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.popLast()
            }
            .onChange(of: updatePinHint) { newValue in
                let truncated = String(newValue.prefix(120))
                updatePinHint = truncated
                pinHint = truncated
            }
            .onChange(of: updatePinHint) { newValue in
                pinHint = newValue
            }
            .onChange(of: updateSignInPolicy) { newValue in
                accessPolicy = newValue
            }
            .trackingSize($listSize)
        }
    }
}
