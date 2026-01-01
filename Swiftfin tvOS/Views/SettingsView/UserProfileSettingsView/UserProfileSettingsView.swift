//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct UserProfileSettingsView: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: SettingsViewModel
    @StateObject
    private var profileImageViewModel: UserProfileImageViewModel

    @State
    private var isPresentingConfirmReset: Bool = false

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        self._profileImageViewModel = StateObject(wrappedValue: UserProfileImageViewModel(user: viewModel.userSession.user.data))
    }

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                UserProfileImage(
                    userID: viewModel.userSession.user.id,
                    source: viewModel.userSession.user.profileImageSource(
                        client: viewModel.userSession.client
                    )
                )
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400)
            }
            .contentView {
                Section {
                    ChevronButton(L10n.security) {
                        router.route(to: .localSecurity)
                    }
                }

                // TODO: Do we want this option on tvOS?
//            Section {
//                // TODO: move under future "Storage" tab
//                //       when downloads implemented
//                Button(L10n.resetSettings) {
//                    isPresentingConfirmReset = true
//                }
//                .foregroundStyle(.red)
//            } footer: {
//                Text(L10n.resetSettingsDescription)
//            }
            }
            .navigationTitle(L10n.user)
            .confirmationDialog(
                L10n.resetSettings,
                isPresented: $isPresentingConfirmReset,
                titleVisibility: .visible
            ) {
                Button(L10n.reset, role: .destructive) {
                    do {
                        try viewModel.userSession.user.deleteSettings()
                    } catch {
                        viewModel.logger.error("Unable to reset user settings: \(error.localizedDescription)")
                    }
                }
            } message: {
                Text(L10n.resetSettingsMessage)
            }
    }
}
