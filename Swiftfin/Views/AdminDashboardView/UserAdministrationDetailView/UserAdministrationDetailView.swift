//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

struct UserAdministrationDetailView: View {

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @ObservedObject
    var observer: UserAdministrationObserver

    @State
    var isPasswordResetPresenting: Bool = false
    @State
    var isPasswordUpdatePresenting: Bool = false
    @State
    var tempPassword: String = ""
    @State
    var tempNewPassword: String = ""
    @State
    var tempPasswordConfirm: String = ""

    var body: some View {
        VStack {
            Text(observer.user.name ?? "")
                .font(.title)
                .padding()

            // Current Password Input
            TextField("Current Password", text: $tempPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // New Password Input
            TextField("New Password", text: $tempNewPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Confirm Password Input
            TextField("Confirm Password", text: $tempPasswordConfirm)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                UserFunctionButton(
                    title: "Reset Password",
                    systemImage: "lock.rotation",
                    warningMessage: "Are you sure you want to reset \(observer.user.name ?? L10n.unknown)'s password?",
                    isPresented: $isPasswordResetPresenting,
                    isDestructive: true
                ) {
                    observer.send(.resetPassword)
                }
                Spacer()
                UserFunctionButton(
                    title: "Save Password",
                    systemImage: "lock.circle.dotted",
                    warningMessage: "Are you sure you want to update \(observer.user.name ?? L10n.unknown)'s password?",
                    isPresented: $isPasswordUpdatePresenting,
                    isDestructive: false
                ) {
                    if tempNewPassword == tempPasswordConfirm {
                        observer.send(.updatePassword(currentPassword: tempPassword, newPassword: tempNewPassword))
                    } else {
                        print("Passwords do not match")
                    }
                }
            }
        }
        .navigationTitle(L10n.user)
    }
}
