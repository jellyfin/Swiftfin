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
        SplitFormWindowView()
            .descriptionView {
                Image("jellyfin-blob-blue")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

                Section {

                    Button {} label: {
                        TextPairView(
                            leading: L10n.version,
                            trailing: "\(UIApplication.appVersion ?? .emptyDash) (\(UIApplication.bundleVersion ?? .emptyDash))"
                        )
                    }

                    ChevronButton(title: "Logs")
                        .onSelect {
                            router.route(to: \.log)
                        }
                }
            }
            .withDescriptionTopPadding()
            .navigationTitle(L10n.settings)

//        Form {
//
//            Button {
//                resetTapped = true
//            } label: {
//                L10n.reset.text
//            }
//        }
//        .alert(L10n.reset, isPresented: $resetTapped, actions: {
//            Button(role: .destructive) {
        ////                viewModel.resetAppSettings()
//                router.dismissCoordinator()
//            } label: {
//                L10n.reset.text
//            }
//        })
    }
}
