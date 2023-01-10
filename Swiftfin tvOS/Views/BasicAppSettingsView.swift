//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI

struct BasicAppSettingsView: View {

    @EnvironmentObject
    private var router: BasicAppSettingsCoordinator.Router

    @ObservedObject
    var viewModel: SettingsViewModel

    @State
    private var resetTapped: Bool = false

    var body: some View {
        Form {

            Section {
                Button {} label: {
                    HStack {
                        L10n.version.text
                        Spacer()
                        Text("\(UIApplication.appVersion ?? .emptyDash) (\(UIApplication.bundleVersion ?? .emptyDash))")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                L10n.about.text
            }

            Button {
                resetTapped = true
            } label: {
                L10n.reset.text
            }
        }
        .alert(L10n.reset, isPresented: $resetTapped, actions: {
            Button(role: .destructive) {
//                viewModel.resetAppSettings()
                router.dismissCoordinator()
            } label: {
                L10n.reset.text
            }
        })
        .navigationTitle(L10n.settings)
    }
}
